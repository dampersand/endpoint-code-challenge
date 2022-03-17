resource "aws_subnet" "publicSubnet" {
  for_each = local.publicSubnets
  vpc_id   = aws_vpc.main.id


  cidr_block              = each.value["cidr"]
  availability_zone       = each.value["az"] #we can do some fancy AZ logic here along with the fancy public subnet logic if desired
  map_public_ip_on_launch = true             #yeaaaaa let's let hackers in and mine some bitcoinnnnn

  tags = {
    "Name" = "subnet ${each.key}"
    "AZ"   = each.value["az"]
  }
}


resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}


#f the default route table, what kind of psychopath uses that
resource "aws_route_table" "baseRouteTable" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Base Route Table"
  }
}

resource "aws_route" "gateway" {
  route_table_id         = aws_route_table.baseRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route_table_association" "publicSubnetToBaseRouteTable" {
  for_each       = local.publicSubnets
  subnet_id      = aws_subnet.publicSubnet[each.key].id
  route_table_id = aws_route_table.baseRouteTable.id
}
