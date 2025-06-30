data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "main" {}

data "aws_s3_bucket" "this" {
  bucket = var.lb_access_logs_bucket_name
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

data "aws_acm_certificate" "this" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  key_types   = ["EC_prime256v1"]
  most_recent = true
}

# Looks like if I use the same bucket for both ALB and NLB access logs, then the last policy will overwrite the first one. 
# So I will need to create one combined policy for both ALB and NLB. Or use two different s3 buckets for ALB and NLB access logs.
# Creating one combined policy for both ALB and NLB didn't help.
# So I have to use two different s3 buckets for ALB and NLB access logs.
data "aws_iam_policy_document" "allow_alb_logging" {
  statement {
    sid       = "AllowAppLoadBalancerWriteOnly"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${data.aws_s3_bucket.this.arn}/${var.lb_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:elasticloadbalancing:${data.aws_s3_bucket.this.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/*"]
    }
  }
}

data "aws_iam_policy_document" "allow_nlb_logging" {
  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [data.aws_s3_bucket.this.arn]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_s3_bucket.this.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${data.aws_s3_bucket.this.arn}/${var.lb_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_s3_bucket.this.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}
