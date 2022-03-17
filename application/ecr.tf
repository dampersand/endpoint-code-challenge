resource "aws_ecr_repository" "images" {
  name = "endpoint-images"

  image_scanning_configuration {
    scan_on_push = true
  }
}