resource "aws_codepipeline" "endpoint" {
  name     = "endpoint-pipe"
  role_arn = aws_iam_role.codepipelineServiceRole.arn

  artifact_store {
    location = aws_s3_bucket.pipeline.id
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      category = "Source"
      name     = "dockerfile"
      owner    = "AWS"
      provider = "S3"
      configuration = {
        "S3Bucket"    = aws_s3_bucket.intake.id,
        "S3ObjectKey" = aws_s3_object.endpointImage.key
      }
      region = "us-west-2"
      output_artifacts = [
        "Dockerfile"
      ]
      run_order = 2
      version   = "1"
    }
  }
  stage {
    name = "Deploy"
    action {
      category = "Deploy"
      name     = "Deploy"
      owner    = "AWS"
      provider = "ElasticBeanstalk"
      configuration = {
        "ApplicationName" = "postgres"
        "EnvironmentName" = "production"
      }
      input_artifacts = [
        "Dockerfile"
      ]
      region    = "us-west-2"
      run_order = 1
      version   = "1"
    }
  }
}

#Dockerrun json to spell out what image to deploy

resource "aws_s3_object" "endpointImage" {
  bucket  = aws_s3_bucket.intake.id
  key     = "endpoint-images/Dockerrun.aws.json"
  content = <<EOF
  {
    "AWSEBDockerrunVersion": "1",
    "Image": {
      "Name": "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-west-2.amazonaws.com/endpoint-images:dantest",
      "Update": "true"
    },
    "Ports": [
      {
        "ContainerPort": 80
      }
    ]
  }
EOF
}
