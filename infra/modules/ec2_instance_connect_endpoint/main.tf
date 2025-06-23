
resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id          = var.subnet_id
  security_group_ids = [aws_security_group.this.id]
  preserve_client_ip = true

  tags = merge(var.tags, {
    Name = "${var.subnet_id}_ec2-connect-endpoint"
  })
}

resource "aws_iam_policy" "this" {
  name        = "ec2-instance-connect"
  description = "Allow to connect to EC2 instance via EC2 Instance Connect Endpoint"
  policy      = data.aws_iam_policy_document.connect_to_ec2_via_ec2_instance_connect_endpoint.json

  tags = merge(var.tags, {
    Name = "${var.subnet_id}_ec2-connect-endpoint-policy"
  })
}

resource "aws_security_group" "this" {
  name        = join("_", [coalesce(var.tags["Name"], "noname"), "ec2-connect-endpoint-sg"])
  description = "security group for EC2 instance connect endpoint"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = join("_", [coalesce(var.tags["Name"], "noname"), "ec2-connect-endpoint-sg"])
  })
}
