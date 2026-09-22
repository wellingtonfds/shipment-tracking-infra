resource "aws_ecr_repository" "application" {
  name                 = format("%s-application", local.name)
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.workload.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "application" {
  repository = aws_ecr_repository.application.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = format("Retain %d images", var.ecr_image_retention_count)
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr_image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}
