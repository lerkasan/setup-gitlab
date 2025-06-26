#tfsec:ignore:aws-elb-alb-not-public: This load balancer should be internet-facing
resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = var.lb_internal
  load_balancer_type               = var.lb_type
  security_groups                  = [aws_security_group.this.id]
  subnets                          = var.public_subnet_ids
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true # For application load balancer this feature is always enabled (true) and cannot be disabled

  # checkov:skip=CKV_AWS_150: Currently deletion protection is disabled to allow for easier testing and development of IaC.
  # enable_deletion_protection = true

  access_logs {
    bucket  = var.lb_access_logs_bucket_name
    prefix  = var.lb_name
    enabled = true
  }

  tags = var.tags

  # Creation of a load balancer will fail if an S3 bucket for access logs is not created or permissions in an S3 bucket policy are not set
  depends_on = [aws_s3_bucket_policy.allow_loadbalancer_to_write_logs]
}

resource "aws_lb_target_group" "this" {
  # checkov:skip=CKV_AWS_378: For a proof of concept we will be terminating TLS at the load balancer.
  for_each = var.target_groups != null ? { for tg in var.target_groups : tg.name => tg } : {}

  name                 = each.value.name
  port                 = each.value.port
  protocol             = each.value.protocol
  vpc_id               = var.vpc_id
  preserve_client_ip   = each.value.preserve_client_ip
  deregistration_delay = each.value.deregistration_delay

  health_check {
    healthy_threshold   = each.value.health_check_healthy_threshold
    interval            = each.value.health_check_interval
    matcher             = each.value.health_check_matcher # "200"
    path                = each.value.health_check_path
    protocol            = each.value.protocol
    timeout             = each.value.health_check_timeout
    unhealthy_threshold = each.value.health_check_unhealthy_threshold
  }

  stickiness {
    type            = each.value.stickiness_type
    cookie_duration = each.value.cookie_duration
  }

  tags = merge(var.tags, {
    Name = "${var.lb_name}-${each.value.name}-lb-tg"
  })
}

resource "aws_lb_listener" "this" {
  for_each = var.listeners != null ? { for listener in var.listeners : listener.port => listener } : {}

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "TLS" || each.value.protocol == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = each.value.protocol == "TLS" || each.value.protocol == "HTTPS" ? each.value.certificate_arn != null ? each.value.certificate_arn : data.aws_acm_certificate.this.arn : null

  default_action {
    type             = each.value.default_action
    target_group_arn = each.value.default_action == "forward" && each.value.target_group_name != null ? aws_lb_target_group.this[each.value.target_group_name].arn : null

    dynamic "redirect" {
      for_each = each.value.default_action == "redirect" ? [1] : []

      content {
        host        = each.value.redirect_host
        port        = each.value.redirect_port
        protocol    = each.value.redirect_protocol
        status_code = each.value.redirect_status_code
      }
    }
  }

  lifecycle {
    #checkov:skip=CKV_AWS_103: False positive: The SSL policy is set to a secure version, and the precondition ensures that only strong policies are used.
    # This precondition can ensure that the selected SSL policy is at least TLS v1.2 to maintain strong security standards
    precondition {
      condition = each.value.ssl_policy == null || contains([
        "ELBSecurityPolicy-TLS13-1-3-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-Res-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-Ext2-2021-06",
        "ELBSecurityPolicy-TLS13-1-2-Ext1-2021-06",
        "ELBSecurityPolicy-TLS-1-2-Ext-2018-06",
        "ELBSecurityPolicy-TLS-1-2-2017-01"
      ], each.value.ssl_policy)
      error_message = "The selected AMI must be for the x86_64 architecture."
    }
  }

  tags = merge(var.tags, {
    Name = "${var.lb_name}-lb-listener-${each.value.port}"
  })
}

resource "aws_s3_bucket_policy" "allow_loadbalancer_to_write_logs" {
  count = var.lb_access_logs_bucket_name != null ? 1 : 0

  bucket = data.aws_s3_bucket.this.id
  policy = var.lb_type == "application" ? data.aws_iam_policy_document.allow_alb_logging.json : var.lb_type == "network" ? data.aws_iam_policy_document.allow_nlb_logging.json : null
}
