terraform {
  required_version = "~> 0.14.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.42.0"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  access_key          = var.aws_access_key
  secret_key          = var.aws_secret_key
  allowed_account_ids = [var.aws_account_id]

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_assume_role}"
  }
}

locals {
  maintenance_on = true
  public_domains = { "example.${var.zone_name}" = local.maintenance_on }
}

data "aws_route53_zone" "selected" {
  zone_id = var.zone_id
}

resource "aws_acm_certificate" "maintenance_weighted" {
  for_each = local.public_domains

  domain_name       = each.key
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "maintenance_weighted_validation" {
  for_each = {
    # resource aws_acm_certificate contains a dynamic block: `domain_validation_options` which need to be flattende before it can be used in for_each
    for dvo in flatten([for d, m in local.public_domains : [aws_acm_certificate.maintenance_weighted[d].domain_validation_options]]) : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.selected.zone_id
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  allow_overwrite = true
  ttl             = 60
}

resource "aws_acm_certificate_validation" "maintenance_weighted_validation" {
  for_each = local.public_domains

  certificate_arn         = aws_acm_certificate.maintenance_weighted[each.key].arn
  validation_record_fqdns = [aws_route53_record.maintenance_weighted_validation[each.key].fqdn]
}

resource "aws_route53_record" "maintenance_weighted_off" {
  for_each = local.public_domains

  name           = each.key
  zone_id        = data.aws_route53_zone.selected.zone_id
  type           = "A"
  set_identifier = "Cluster"

  alias {
    zone_id                = data.aws_route53_zone.selected.zone_id
    name                   = "\\052.${data.aws_route53_zone.selected.name}"
    evaluate_target_health = false
  }

  weighted_routing_policy {
    weight = each.value ? 0 : 1
  }
}

resource "aws_route53_record" "maintenance_weighted_on" {
  for_each = local.public_domains

  name           = each.key
  zone_id        = data.aws_route53_zone.selected.zone_id
  type           = "A"
  set_identifier = "ClusterMaintenance"

  alias {
    zone_id                = aws_api_gateway_domain_name.public_domain[each.key].regional_zone_id
    name                   = aws_api_gateway_domain_name.public_domain[each.key].regional_domain_name
    evaluate_target_health = false
  }

  weighted_routing_policy {
    weight = each.value ? 1 : 0
  }
}

resource "aws_api_gateway_domain_name" "public_domain" {
  for_each = local.public_domains

  domain_name              = each.key
  regional_certificate_arn = aws_acm_certificate_validation.maintenance_weighted_validation[each.key].certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_base_path_mapping" "public_domain" {
  for_each = local.public_domains

  domain_name = aws_api_gateway_domain_name.public_domain[each.key].domain_name
  api_id      = module.maintenance_example.api_id
  stage_name  = module.maintenance_example.stage_name
}

module "maintenance_example" {
  source = "../../"

  zone_id           = data.aws_route53_zone.selected.id
  api_name          = "maintenance_example"
  api_stage_name    = "example"
  api_domain_name   = "maintenance-example.${var.zone_name}"
  maintenance_modes = local.maintenance_on
  html_template     = { "mailto" = "E@MA.IL", "team" = "TEAM" }
  tags              = { ManagedBy = "terraform" }
}
