terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  azs_count = length(var.azs)

  # One NAT gateway per private subnet's AZ, or one shared. Sizing this off the
  # private subnets means a spare public subnet does not buy an idle NAT.
  nat_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0

  # A private route table per NAT gateway. Without NAT, or with one shared NAT,
  # every private subnet uses the same table.
  private_route_table_count = var.enable_nat_gateway && !var.single_nat_gateway ? length(var.private_subnets) : 1
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

# AWS gives every VPC a default security group that allows traffic between its
# members. Nothing here uses it, so take its rules away. A resource that lands
# in it by mistake then gets no access instead of open access.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-default-deny" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index % local.azs_count]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index % local.azs_count]

  tags = merge(var.tags, {
    Name                              = "${var.name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })

  lifecycle {
    precondition {
      condition     = !var.enable_nat_gateway || var.single_nat_gateway || length(var.public_subnets) >= length(var.private_subnets)
      error_message = "With a NAT gateway per AZ, each private subnet needs a public subnet at the same index to hold its NAT gateway. Add public subnets or set single_nat_gateway = true."
    }
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route_table" "private" {
  count  = local.private_route_table_count
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-private-${count.index + 1}" })

}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[local.private_route_table_count == 1 ? 0 : count.index].id
}

resource "aws_cloudwatch_log_group" "flow_log" {
  #checkov:skip=CKV_AWS_158:KMS encryption is opt-in through flow_log_kms_key_id. A key the module creates would be one more thing to own.
  #checkov:skip=CKV_AWS_338:Retention is a cost choice. Flow logs are large, so the default is 30 days and flow_log_retention_days raises it.
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/flow-logs/${var.name}"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.flow_log_kms_key_id
  tags              = var.tags
}

resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-log"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-log"
  role  = aws_iam_role.flow_log[0].id
  # Scoped to the one log group this module creates. The group already exists,
  # so the role has no need to create groups.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
      Resource = [
        aws_cloudwatch_log_group.flow_log[0].arn,
        "${aws_cloudwatch_log_group.flow_log[0].arn}:*",
      ]
    }]
  })
}

resource "aws_flow_log" "this" {
  count           = var.enable_flow_logs ? 1 : 0
  iam_role_arn    = aws_iam_role.flow_log[0].arn
  log_destination = aws_cloudwatch_log_group.flow_log[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id
}
