data "aws_vpc" "this" {
  id = var.vpc_id
}

# The ec2:Describe* API actions do not support resource-level permissions. Therefore, the * wildcard is necessary in the Resource element.
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/permissions-for-ec2-instance-connect-endpoint.html#iam-CreateInstanceConnectEndpoint
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "connect_to_ec2_via_ec2_instance_connect_endpoint" {

  statement {
    sid    = "SendSSHPublicKey"
    effect = "Allow"
    actions = [
      "ec2-instance-connect:SendSSHPublicKey"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:osuser"
      values   = [local.ec2_os_user]
    }
  }

  statement {
    sid    = "EC2ConnectEndpoint"
    effect = "Allow"
    actions = [
      "ec2-instance-connect:OpenTunnel"
    ]
    resources = [aws_ec2_instance_connect_endpoint.this.arn]

    condition {
      test     = "IpAddress"
      variable = "ec2-instance-connect:privateIpAddress"
      values   = [data.aws_vpc.this.cidr_block]
    }

    condition {
      test     = "NumericEquals"
      variable = "ec2-instance-connect:remotePort"
      values   = [local.ssh_port]
    }

    dynamic "condition" {
      for_each = var.admin_public_ips != null ? toset(var.admin_public_ips) : toset([])

      content {
        test     = "IpAddress"
        variable = "aws:SourceIp"
        values   = [condition.value]
      }
    }
  }

  statement {
    sid    = "EC2DescribeConnectEndpoints"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceConnectEndpoints"
    ]
    resources = ["*"]
  }
}