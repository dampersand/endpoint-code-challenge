# endpoint-code-challenge

# Synopsis

This is a quick-and-dirty set of Terraform code that sets up an elastic beanstalk instance on a fresh AWS account.

# Challenge Text

In this exercise, we want you to use terraform and the tooling of your choice to accomplish the following tasks.  


- 1 VPC
- 1 Public Subnet
- 1 Elastic Beanstalk instance for Docker
- Choose a container to deploy from the following:
  - https://hub.docker.com/_/postgres
  - https://hub.docker.com/_/kibana (note: you do not need to have data fed into Kibana, the requirement is only for the Kibana UI running on Elastic Beanstalk)
  - https://hub.docker.com/r/jenkins/jenkins
  - https://hub.docker.com/_/ghost
- A simple script to deploy a single container from ECR to Elastic Beanstalk
  - Use OpsWorks and/or CodeBuild/CodePipeline

# Setup
1. ~~unpack the tarball into a convenient working directory~~ clone this repo
2. inspect the code - I can promise up and down it's not a bitcoin miner, but you should probably still be sure. :)
3. make sure you have terraform installed (I pinned the version), along with awscli/boto/etc as necessary.
4. Have an aws account.  This demo is just going to use what's in your ~/.aws directory, so run `aws configure` as necessary.
5. In the code, descend to the 'baseInfra' directory and run `terraform apply.` **This satisfies the requirement to create a VPC/public network/associated infrastructure bric-a-brac.**
6. In the code, descend to the 'application' directory and run `terraform apply.`  **This satisfies the requirement to create an Elastic Beanstalk for docker and creates a CD pipeline to install stuff from ECR to the beanstalk.**

# Usage 

**To satisfy the requirement "pick a container and deploy it"**: When the 'application' module was applied, it created a postgres 'application version.'  You should simply need to navigate to your aws console, find the new elasticbeanstalk application (entitled postgres), and there you will find an application version entitled "postgresDefault."  Click 'deploy' to deploy a simple postgres container to the beanstalk's EC2 instances.  May I recommend nginx next time?  Easier to curl against, no need to install psql and know the default creds to see if it's up.

**To satisfy the requirement "[make] a simple script to deploy a single container from ECR to Elastic Beanstalk"** It sounds like you're asking for a CD pipeline that can be used with any CI, but not asking me to build the CI... so I'm gonna give you a modularized CD pipeline that you can hook into your CI.  The thing is you shouldn't need a script to do this - if your container already exists on ECR and needs to go to beanstalk, codepipeline handles that fairly well... so we are going script-free. :)  You will find a codepipeline (probably in a failed state) that is watching 's3://endpoint-codepipeline-bucket/endpoint-images/Dockerrun.aws.json' like a hawk.  If that dockerrun.aws.json object (which includes information about where to find the image to deploy) ever changes, the codepipeline will automatically run the deployment.  When `application` was applied, an example dockerrun.aws.json object would have been created (and it's very likely that since this object refers to a docker image that doesn't exist, the pipeline may have failed out of the box.  That's pretty expected).  To see the pipeline in action, you'll need to act in the role of CI:
1. Push any ol' image (that listens on port 80) to the 'endpoint-images' ECR.  tag it 'dantest'.  If you're really diligent, do whatever code tests you like.
2. click the 'release change' button on the codepipeline that was created.  This should trigger a deployment.
An alternate method of triggering the CD would be to:
1. Push an image (that listens on port 80) to the 'endpoint-images' ECR, but tag it anything you want.
2. Upload a fresh Dockerrun.aws.json to that s3 bucket that specifies the new tag - the codepipeline will automatically pick up the trigger and run a deployment.
Heck, if you're having trouble pushing the ECR image, feel free to just change the dockerrun.aws.json completely to read `nginx:latest`... but I'll feel bad, I didn't write that `iam_role_policy_attachment` for nothing. ;)

# Suggestions/Future Work
This is obviously not a production-ready system.  It includes SEVERAL flaws.  Here are a couple off top of my head:
1. much of the 'baseInfra' section should be converted to reusable modules.  VPC modules, for instance, should be able to auto-calculate desired subnets instead of accepting a list of subnets, etc.
2. We should add some form of 'assume role' in the aws provider for CI/CD purposes - you want terraform running plans nightly in CI/CD to look for trouble, right?
3. Static defaults should be ingested from a module instead - for instance, the 'publicSubnets' local in the baseInfra section should probably be part of that list of defaults - a single location where folks can change how the infrastructure should look.  Other things like cidrs and AWS account numbers should be found there.
4. Module outputs are always a tricky subject.  Allowing people to use data sources willy nilly means you end up with lots of ghost dependencies.  On the opposite side of the spectrum, it's good to have module writers specify a 'demilitarized zone' of maintained outputs that can be imported by other modules instead of terraform_remote_state.  This can be done by literally generating a 'sanitized outputs' submodule for every module that is allowed to read 'terraform_remote_state'.  It then becomes the maintainer's job to make sure the sanitized outputs are always working - it's like a guarantee to any other module users that 'yes, my module will never suddenly just lose an output.'  Lots of extra overhead, though.
5. security is completely nil here.  That's an internet gateway and the EC2 images are getting public addresses.  No security groups included either, nor bucket ACLs.  Obviously take this down when you're done.
6. The pipeline artifacts should absolutely NOT be built in terraform - I'm talking specifically about line 52 in application/pipeline.tf.  Pipeline artifacts should be defined by the CI, not by the CD, and they should be replaced or updated every time there's a new build.  I would envision something that is watching a repo, running docker build from a dockerfile, tagging the image with the repo's sha, and using that to generate the dockerrun.aws.json. At that point, your CI should publish the image to ECR and push the dockerrun.json to the correct location in the S3 bucket.  this will automatically trigger the pipeline.