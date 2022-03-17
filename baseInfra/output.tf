output "vpc_id" {
  value = aws_vpc.main.id
}

#Ugly lookin' output, but this lets us carry through dynamic information about subnets from a single input source (which right now is our locals)
output "public_subnets" {
  value = {
    for index, subnetInfo in local.publicSubnets : index => merge(subnetInfo, { "id" = aws_subnet.publicSubnet[index].id })
  }
}
