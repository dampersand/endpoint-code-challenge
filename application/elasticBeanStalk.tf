#Gonna need to know info from the base infrastructure
data "aws_vpc" "baseVPC" {
  id = data.terraform_remote_state.baseInfra.outputs.vpc_id
}

data "aws_subnet" "publicSubnet" {
  id = data.terraform_remote_state.baseInfra.outputs.public_subnets[local.publicSubnet]["id"]
}

resource "aws_elastic_beanstalk_application" "postgres" {
  name        = "postgres"
  description = "EB application for docker-postgres"
}

resource "aws_elastic_beanstalk_environment" "production" {
  name                = "production"
  application         = aws_elastic_beanstalk_application.postgres.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.11 running Docker" #Hardcoding this feels very bad, but that's aws, baby

  #for feedback loop purposes
  wait_for_ready_timeout = "5m"


  #Settings specific to the docker platform

  setting {
    name      = "VPCId"
    namespace = "aws:ec2:vpc"
    value     = data.aws_vpc.baseVPC.id
  }

  setting {
    name      = "Subnets"
    namespace = "aws:ec2:vpc"
    value     = data.aws_subnet.publicSubnet.id
  }

  #Using some default built-in roles from aws
  setting {
    name      = "IamInstanceProfile"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = data.aws_iam_role.beanstalkEC2Policy.name
  }
  setting {
    name      = "ServiceRole"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "aws-elasticbeanstalk-service-role"
  }
}


#creates a default application that is expected to NOT be used after creation.  Start by uploading it to the bucket:
resource "aws_s3_object" "postgresDefault" {
  bucket = aws_s3_bucket.intake.id
  key    = "postgresDefault/Dockerrun.aws.json"
  source = "files/Dockerrun.aws.json.default"
}

resource "aws_elastic_beanstalk_application_version" "postgresDefault" {
  name        = "postgresDefault"
  application = aws_elastic_beanstalk_application.postgres.name
  description = "Straight up postgres, don't even think about it"
  bucket      = aws_s3_bucket.intake.id
  key         = aws_s3_object.postgresDefault.id

}