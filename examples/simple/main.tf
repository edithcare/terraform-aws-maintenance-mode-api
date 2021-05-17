terraform {
  required_version = "~> 0.14.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.39.0"
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
  zone_name            = "ZONE_NAME_COM"
  zone_id              = "ZONE_ID"
  maintenance_api_name = "API_NAME"
  maintenance_on       = false
  public_domains = {
    "foo.${local.zone_name}" = local.maintenance_on
  }
  public_domain_certs = { for d, m in local.public_domains : d => aws_acm_certificate_validation.maintenance_weighted_validation[d].certificate_arn }
  tags = {
    ManagedBy = "terraform"
  }
}

data "aws_route53_zone" "selected" {
  zone_id = local.zone_id
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
    zone_id                = module.maintenance_api_ddev.aws_api_gateway_domain_name[each.key].regional_zone_id
    name                   = module.maintenance_api_ddev.aws_api_gateway_domain_name[each.key].regional_domain_name
    evaluate_target_health = false
  }

  weighted_routing_policy {
    weight = each.value ? 1 : 0
  }
}

resource "aws_acm_certificate" "maintenance_weighted" {
  for_each = local.public_domains

  domain_name       = each.key
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource aws_acm_certificate contains a dynamic block: `domain_validation_options` which need to be flattende before it can be used in for_each

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate#referencing-domain_validation_options-with-for_each-based-resources
https://www.terraform.io/docs/language/functions/flatten.html#flattening-nested-structures-for-for_each
*/
locals {
  domain_validation_options = flatten([
    for d, m in local.public_domains : [aws_acm_certificate.maintenance_weighted[d].domain_validation_options]
  ])
}

resource "aws_route53_record" "maintenance_weighted_validation" {
  for_each = {
    for dvo in local.domain_validation_options : dvo.domain_name => {
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

module "maintenance_api_ddev" {
  source = "../../"

  zone_id           = data.aws_route53_zone.selected.id
  api_name          = local.maintenance_api_name
  api_stage_name    = local.maintenance_api_name
  api_domain_name   = "${local.maintenance_api_name}.${local.zone_name}"
  public_domains    = local.public_domain_certs # [{"domain": "cert_arn"}]
  maintenance_modes = local.maintenance_on
  html_template     = { "mailto" = "support@edith.care", "team" = "edith.care" }
  tags              = local.tags
}
