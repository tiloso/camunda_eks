resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "main" {
  name = var.domain
}

resource "aws_route53_record" "acm_main" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 300
  type    = each.value.type
  zone_id = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_main : record.fqdn]
}


resource "aws_acm_certificate" "zeebe" {
  domain_name       = "zeebe.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_zeebe" {
  for_each = {
    for dvo in aws_acm_certificate.zeebe.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 300
  type    = each.value.type
  zone_id = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "zeebe" {
  certificate_arn         = aws_acm_certificate.zeebe.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_zeebe : record.fqdn]
}
