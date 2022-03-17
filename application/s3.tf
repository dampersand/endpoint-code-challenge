resource "aws_s3_bucket" "intake" {
  bucket = "${local.project}-intake-bucket"
}

resource "aws_s3_bucket" "pipeline" {
  bucket = "${local.project}-codepipeline-bucket"
}

resource "aws_s3_bucket_versioning" "intakeVersioningOn" {
  bucket = aws_s3_bucket.intake.id
  versioning_configuration {
    status = "Enabled"
  }
}