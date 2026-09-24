resource "aws_acm_certificate" "api" {
  count = var.enable_public_edge ? 1 : 0

  domain_name       = var.application_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "certificate" {
  for_each = var.enable_public_edge ? {
    for option in aws_acm_certificate.api[0].domain_validation_options : option.domain_name => {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  } : {}

  zone_id = data.aws_route53_zone.public[0].zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "api" {
  count = var.enable_public_edge ? 1 : 0

  certificate_arn         = aws_acm_certificate.api[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate : record.fqdn]
}

resource "aws_lb" "application" {
  name                       = format("%s-api", local.name)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = var.alb_deletion_protection
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "application" {
  name        = format("%s-api", local.name)
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path    = "/api/v1/health"
    matcher = "200-399"
  }
}

resource "aws_lb_listener" "https" {
  count = var.enable_public_edge ? 1 : 0

  load_balancer_arn = aws_lb.application.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.api[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

resource "aws_lb_listener" "http" {
  count = var.enable_public_edge ? 0 : 1

  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

resource "aws_wafv2_web_acl" "api" {
  count = var.enable_public_edge ? 1 : 0

  name  = format("%s-api", local.name)
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedCommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managed-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = format("%s-api", local.name)
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "api" {
  count = var.enable_public_edge ? 1 : 0

  resource_arn = aws_lb.application.arn
  web_acl_arn  = aws_wafv2_web_acl.api[0].arn
}

resource "aws_route53_record" "api" {
  count = var.enable_public_edge ? 1 : 0

  zone_id = data.aws_route53_zone.public[0].zone_id
  name    = var.application_domain
  type    = "A"

  alias {
    name                   = aws_lb.application.dns_name
    zone_id                = aws_lb.application.zone_id
    evaluate_target_health = true
  }
}
