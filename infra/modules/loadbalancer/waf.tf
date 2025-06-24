resource "aws_wafv2_web_acl" "this" {
  #checkov:skip=CKV2_AWS_31: For the purposes of this proof of concept, we don't want to use Kinesis Firehose for WAF logging.  
  # https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-logging-33
  count = var.waf_enabled ? 1 : 0

  name  = "${var.lb_name}-webacl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontVisibilityConfig"
    sampled_requests_enabled   = true
  }

  tags = merge(var.tags, {
    Name = "${var.lb_name}-waf-acl"
  })
}

resource "aws_wafregional_web_acl_association" "this" {
  count = var.waf_enabled ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_id   = aws_wafv2_web_acl.this[0].id
}