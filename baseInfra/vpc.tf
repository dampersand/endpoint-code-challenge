resource "aws_vpc" "main" {
  cidr_block = local.cidr

  tags = {
    Name = "${local.project}-vpc"
  }
}
