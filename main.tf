locals {
  maintenance_on  = "on"
  maintenance_off = "off"

  tags = {
    ProductDomain = var.maintenance_api_name
    ManagedBy     = "Terraform"
  }
}

resource "aws_api_gateway_rest_api" "maintenance_api" {
  name = var.maintenance_api_name
  tags = local.tags

  endpoint_configuration {
    types = [
      "REGIONAL",
    ]
  }
}

data "aws_api_gateway_resource" "maintenance_api" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  path        = "/"
}

resource "aws_api_gateway_method" "maintenance_api" {
  rest_api_id      = aws_api_gateway_rest_api.maintenance_api.id
  resource_id      = data.aws_api_gateway_resource.maintenance_api.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "maintenance_api" {
  rest_api_id          = aws_api_gateway_rest_api.maintenance_api.id
  resource_id          = data.aws_api_gateway_resource.maintenance_api.id
  http_method          = aws_api_gateway_method.maintenance_api.http_method
  type                 = "MOCK"
  passthrough_behavior = "NEVER"
  request_templates = {
    "application/json" = <<EOT
{
  #if( $stageVariables.maintenance == "${local.maintenance_on}" )
    "statusCode": 503
  #else
    "statusCode": 200
  #end
}
      EOT
  }
  timeout_milliseconds = 29000
}

resource "aws_api_gateway_method_response" "maintenance_api_response_200" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "maintenance_api_response_503" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api.http_method
  status_code = "503"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "maintenance_api_response_200" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api.http_method
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = ""
  }
  selection_pattern = "200"
  status_code       = aws_api_gateway_method_response.maintenance_api_response_200.status_code
}

resource "aws_api_gateway_integration_response" "maintenance_api_response_503" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api.http_method
  status_code = aws_api_gateway_method_response.maintenance_api_response_503.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_deployment" "maintenance_api" {
  depends_on  = [aws_api_gateway_integration.maintenance_api, aws_api_gateway_method.maintenance_api, aws_api_gateway_method_response.maintenance_api_response_200, aws_api_gateway_method_response.maintenance_api_response_503, aws_api_gateway_integration_response.maintenance_api_response_200, aws_api_gateway_integration_response.maintenance_api_response_503]
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  stage_name  = "default"
}

resource "aws_api_gateway_stage" "maintenance_api" {
  for_each = var.environments

  rest_api_id   = aws_api_gateway_rest_api.maintenance_api.id
  stage_name    = each.key
  deployment_id = aws_api_gateway_deployment.maintenance_api.id

  variables = {
    "maintenance" = var.maintenance_modes[each.key] ? local.maintenance_on : local.maintenance_off
  }
}


data "aws_route53_zone" "name" {
  name = var.zone_name
}

resource "aws_api_gateway_domain_name" "maintenance_api" {
  for_each = var.environments

  domain_name              = each.value
  regional_certificate_arn = aws_acm_certificate_validation.maintenance_api_cert.certificate_arn
  tags                     = local.tags

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "maintenance_api" {
  for_each = var.environments

  name    = aws_api_gateway_domain_name.maintenance_api[each.key].domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.name.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.maintenance_api[each.key].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.maintenance_api[each.key].regional_zone_id
  }
}

resource "aws_acm_certificate" "maintenance_api" {
  domain_name       = element(var.certificate_domain_names, 0)
  validation_method = "DNS"
  tags = merge(local.tags, {
    Name = var.maintenance_api_name
  })

  subject_alternative_names = length(var.certificate_domain_names) > 1 ? slice(var.certificate_domain_names, 1, length(var.certificate_domain_names)) : []

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "maintenance_api_cert_validations" {
  count = length(var.certificate_domain_names)

  name    = element(aws_acm_certificate.maintenance_api.domain_validation_options.*.resource_record_name, count.index)
  type    = element(aws_acm_certificate.maintenance_api.domain_validation_options.*.resource_record_type, count.index)
  zone_id = data.aws_route53_zone.name.id
  records = [element(aws_acm_certificate.maintenance_api.domain_validation_options.*.resource_record_value, count.index)]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "maintenance_api_cert" {
  certificate_arn         = aws_acm_certificate.maintenance_api.arn
  validation_record_fqdns = aws_route53_record.maintenance_api_cert_validations.*.fqdn
}

resource "aws_api_gateway_base_path_mapping" "maintenance_api" {
  for_each = var.environments

  api_id      = aws_api_gateway_rest_api.maintenance_api.id
  stage_name  = aws_api_gateway_stage.maintenance_api[each.key].stage_name
  domain_name = aws_api_gateway_domain_name.maintenance_api[each.key].domain_name
}
