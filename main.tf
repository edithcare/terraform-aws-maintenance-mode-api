terraform {
  required_version = "~> 0.14.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.39.0"
    }
  }
}

locals {
  maintenance_on  = "on"
  maintenance_off = "off"

  tags = merge(var.tags, {
    ManagedBy   = "terraform"
    CreatedFrom = "app.terraform.io/edithcare/maintenance-mode-api/aws"
  })

  cors_integration_response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,HEAD,GET'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'7200'"
  }
  cors_method_response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

# ------------------------------------------------------ route53 ------------------------------------------------------

resource "aws_route53_record" "maintenance_api" {
  type    = "A"
  name    = aws_api_gateway_domain_name.restapi.domain_name
  zone_id = var.zone_id

  alias {
    zone_id                = aws_api_gateway_domain_name.restapi.regional_zone_id
    name                   = aws_api_gateway_domain_name.restapi.regional_domain_name
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "maintenance_api" {
  domain_name       = var.api_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_route53_record" "maintenance_api_cert_validations" {
  for_each = {
    for dvo in aws_acm_certificate.maintenance_api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.zone_id
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  allow_overwrite = true
  ttl             = 60
}

resource "aws_acm_certificate_validation" "maintenance_api_cert" {
  certificate_arn         = aws_acm_certificate.maintenance_api.arn
  validation_record_fqdns = [for record in aws_route53_record.maintenance_api_cert_validations : record.fqdn]
}

# ------------------------------------------------------ API Gateway _ ------------------------------------------------------

resource "aws_api_gateway_rest_api" "restapi" {
  name = var.api_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.tags
}

data "aws_api_gateway_resource" "restapi" {
  rest_api_id = aws_api_gateway_rest_api.restapi.id
  path        = "/"
}

resource "aws_api_gateway_deployment" "restapi" {
  rest_api_id = aws_api_gateway_rest_api.restapi.id


  # triggers - (Optional) Map of arbitrary keys and values that, when changed, will trigger a redeployment.
  #  to force a redeployment without changing these keys/values, use `terraform taint`
  triggers = {
    redeployment = jsonencode([

      aws_api_gateway_method.options,
      aws_api_gateway_method.get,

      aws_api_gateway_integration.options,
      aws_api_gateway_integration.get,


      aws_api_gateway_integration_response.options_response_200,
      aws_api_gateway_integration_response.get_response_200,
      aws_api_gateway_integration_response.get_response_503,

      aws_api_gateway_method_response.options_response_200,
      aws_api_gateway_method_response.get_response_200,
      aws_api_gateway_method_response.get_response_503,
    ])
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "restapi" {
  stage_name    = var.api_stage_name
  rest_api_id   = aws_api_gateway_rest_api.restapi.id
  deployment_id = aws_api_gateway_deployment.restapi.id

  variables = {
    "maintenance" = var.maintenance_modes ? local.maintenance_on : local.maintenance_off
  }
}

resource "aws_api_gateway_domain_name" "restapi" {
  domain_name              = var.api_domain_name
  regional_certificate_arn = aws_acm_certificate_validation.maintenance_api_cert.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.tags
}

resource "aws_api_gateway_base_path_mapping" "restapi" {
  api_id      = aws_api_gateway_rest_api.restapi.id
  stage_name  = aws_api_gateway_stage.restapi.stage_name
  domain_name = aws_api_gateway_domain_name.restapi.domain_name
}

# ------------------------------------------------------ method: OPTION ------------------------------------------------------

resource "aws_api_gateway_method" "options" {
  rest_api_id          = aws_api_gateway_rest_api.restapi.id
  resource_id          = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method          = "OPTIONS"
  authorization        = "NONE"
  api_key_required     = false
  authorization_scopes = []
  authorizer_id        = ""
  operation_name       = ""
  request_models       = {}
  request_parameters   = {}
  request_validator_id = ""
}

resource "aws_api_gateway_integration" "options" {
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  rest_api_id          = aws_api_gateway_rest_api.restapi.id
  resource_id          = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method          = aws_api_gateway_method.options.http_method
  request_templates    = { "application/json" = jsonencode({ statusCode = 200 }) }
  timeout_milliseconds = 29000
  cache_key_parameters = []
  request_parameters   = {}
}

resource "aws_api_gateway_integration_response" "options_response_200" {
  depends_on = [aws_api_gateway_integration.options]

  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.options.http_method
  response_parameters = local.cors_integration_response_parameters
  status_code         = "200"
  response_templates  = {}
}

resource "aws_api_gateway_method_response" "options_response_200" {
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.options.http_method
  response_parameters = local.cors_method_response_parameters
  response_models     = { "application/json" = "Empty" }
  status_code         = "200"
}

# ------------------------------------------------------ method: GET ------------------------------------------------------

resource "aws_api_gateway_method" "get" {
  rest_api_id          = aws_api_gateway_rest_api.restapi.id
  resource_id          = data.aws_api_gateway_resource.restapi.id
  http_method          = "GET"
  authorization        = "NONE"
  api_key_required     = false
  authorization_scopes = []
  authorizer_id        = ""
  operation_name       = ""
  request_models       = {}
  request_parameters   = {}
  request_validator_id = ""
}

resource "aws_api_gateway_integration" "get" {
  depends_on = [aws_api_gateway_method.get]

  type                 = "MOCK"
  passthrough_behavior = "NEVER"
  rest_api_id          = aws_api_gateway_rest_api.restapi.id
  resource_id          = data.aws_api_gateway_resource.restapi.id
  http_method          = aws_api_gateway_method.get.http_method
  request_templates = {
    "application/json" = <<-EOT
    {
      #if( $stageVariables.maintenance == "${local.maintenance_on}" )
      statusCode: 503
      #else
      statusCode: 200
      #end
    }
    EOT
  }
  timeout_milliseconds = 29000
  cache_key_parameters = []
  request_parameters   = {}
}

resource "aws_api_gateway_integration_response" "get_response_200" {
  depends_on = [aws_api_gateway_integration.get]

  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = data.aws_api_gateway_resource.restapi.id
  http_method         = aws_api_gateway_method.get.http_method
  response_parameters = local.cors_integration_response_parameters
  selection_pattern   = "200"
  status_code         = "200"
  response_templates  = { "application/json" = "" }
}

resource "aws_api_gateway_method_response" "get_response_200" {
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = data.aws_api_gateway_resource.restapi.id
  http_method         = aws_api_gateway_method.get.http_method
  status_code         = aws_api_gateway_integration_response.get_response_200.status_code
  response_parameters = local.cors_method_response_parameters
  response_models     = { "application/json" = "Empty" }
}

resource "aws_api_gateway_integration_response" "get_response_503" {
  depends_on = [aws_api_gateway_integration.get]

  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.get.http_method
  response_parameters = local.cors_integration_response_parameters
  status_code         = "503"
  response_templates  = { "text/html" = templatefile("${path.module}/index.html", var.html_template) }
}

resource "aws_api_gateway_method_response" "get_response_503" {
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.get.http_method
  response_parameters = local.cors_method_response_parameters
  status_code         = "503"
  response_models     = { "text/html" = "Empty" }
}
