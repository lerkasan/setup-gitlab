resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}


resource "aws_route53_record" "subdomain" {
  for_each = var.subdomains

  zone_id = data.aws_route53_zone.this.zone_id
  name    = join(".", [each.key, data.aws_route53_zone.this.name])
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "subdomain" {
  for_each = var.subdomains

  domain_name       = join(".", [each.key, data.aws_route53_zone.this.name])
  validation_method = "DNS"
}


resource "aws_route53_record" "gitlab_subdomain_validation" {
  # TODO: figure out nested for_each and avoid duplication of resource "aws_route53_record" "gitlab_subdomain_validation" and "registry_subdomain_validation"
  # https://discuss.hashicorp.com/t/how-to-deal-with-nested-for-each-loops-in-dependent-ressources/50551/2

  for_each = {
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
}

resource "aws_route53_record" "registry_subdomain_validation" {
  # TODO: figure out nested for_each and avoid duplication of resource "aws_route53_record" "gitlab_subdomain_validation" and "registry_subdomain_validation"
  # https://discuss.hashicorp.com/t/how-to-deal-with-nested-for-each-loops-in-dependent-ressources/50551/2

  for_each = {
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
}


resource "aws_lb_listener_certificate" "subdomain" {
  for_each = var.subdomains

  listener_arn    = aws_lb_listener.this[local.https_port].arn
  certificate_arn = aws_acm_certificate.subdomain[each.key].arn
}
