resource "aws_route53_record" "this" {
  count = var.lb_internal ? 0 : 1

  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }

  lifecycle {
    ignore_changes = [
      zone_id,
      multivalue_answer_routing_policy,
      records,
      ttl
    ]
  }
}


resource "aws_route53_record" "subdomain" {
  for_each = var.lb_internal ? [] : var.subdomains

  zone_id = data.aws_route53_zone.this.zone_id
  name    = join(".", [each.key, data.aws_route53_zone.this.name])
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [
      zone_id,
      multivalue_answer_routing_policy,
      records,
      ttl
    ]
  }
}

resource "aws_acm_certificate" "subdomain" {
  for_each = var.subdomains

  domain_name       = join(".", [each.key, data.aws_route53_zone.this.name])
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "gitlab_subdomain_validation" {
  for_each = var.lb_internal ? {} : {
    for dvo in aws_acm_certificate.subdomain["gitlab"].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id

  lifecycle {
    ignore_changes = [
      zone_id,
      multivalue_answer_routing_policy
    ]
  }
}

resource "aws_route53_record" "registry_subdomain_validation" {
  for_each = var.lb_internal ? {} : {
    for dvo in aws_acm_certificate.subdomain["registry"].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id

  lifecycle {
    ignore_changes = [
      zone_id,
      multivalue_answer_routing_policy
    ]
  }
}

resource "aws_lb_listener_certificate" "subdomain" {
  for_each = var.lb_internal ? var.subdomains : []

  listener_arn    = aws_lb_listener.this[local.https_port].arn
  certificate_arn = aws_acm_certificate.subdomain[each.key].arn
}
