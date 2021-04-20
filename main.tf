terraform {
  required_version = "~> 0.14.0"

  required_providers {
    aws = ">= 3.30.0"
  }
}

locals {
  maintenance_on  = "on"
  maintenance_off = "off"

  tags = {
    ManagedBy = "terraform"
  }

  cors_integration_response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE'"
    # "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,HEAD,GET'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Access-Control-Max-Age"      = "'7200'"
  }
  cors_method_response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }
}

/********************************************** route53 **************************************************************************/

data "aws_route53_zone" "name" {
  name = var.zone_name
}

resource "aws_route53_record" "maintenance_api" {
  type    = "A"
  name    = aws_api_gateway_domain_name.restapi.domain_name
  zone_id = data.aws_route53_zone.name.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.restapi.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.restapi.regional_zone_id
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

  zone_id = data.aws_route53_zone.name.id
  name    = element(aws_acm_certificate.maintenance_api.domain_validation_options.*.resource_record_name, count.index)
  type    = element(aws_acm_certificate.maintenance_api.domain_validation_options.*.resource_record_type, count.index)
  records = [element(aws_acm_certificate.maintenance_api.domain_validation_options.*.resource_record_value, count.index)]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "maintenance_api_cert" {
  certificate_arn         = aws_acm_certificate.maintenance_api.arn
  validation_record_fqdns = aws_route53_record.maintenance_api_cert_validations.*.fqdn
}

/********************************************** API Gateway _ **************************************************************************/

resource "aws_api_gateway_rest_api" "restapi" {
  name = var.maintenance_api_name
  tags = local.tags

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

data "aws_api_gateway_resource" "restapi" {
  rest_api_id = aws_api_gateway_rest_api.restapi.id
  path        = "/"
}

resource "aws_api_gateway_deployment" "restapi" {
  rest_api_id = aws_api_gateway_rest_api.restapi.id

  triggers = {
    redeployment = sha1(jsonencode([
      # aws_api_gateway_method.ANY,
      aws_api_gateway_method.options,
      aws_api_gateway_method.get,

      # aws_api_gateway_integration.ANY,
      aws_api_gateway_integration.options,
      aws_api_gateway_integration.get,

      # aws_api_gateway_integration_response.ANY_response_200,
      # aws_api_gateway_integration_response.ANY_response_503,
      aws_api_gateway_integration_response.options_response_200,
      aws_api_gateway_integration_response.get_response_200,
      aws_api_gateway_integration_response.get_response_503,

      # aws_api_gateway_method_response.ANY_response_200,
      # aws_api_gateway_method_response.ANY_response_503,
      aws_api_gateway_method_response.options_response_200,
      aws_api_gateway_method_response.get_response_200,
      aws_api_gateway_method_response.get_response_503,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "restapi" {
  stage_name    = var.environments
  rest_api_id   = aws_api_gateway_rest_api.restapi.id
  deployment_id = aws_api_gateway_deployment.restapi.id

  variables = {
    "maintenance" = var.maintenance_modes ? local.maintenance_on : local.maintenance_off
  }
}


resource "aws_api_gateway_domain_name" "restapi" {
  domain_name              = var.domain_name
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


resource "aws_api_gateway_domain_name" "public_domain" {

  for_each = length(var.certificate_domain_names) > 1 ? toset(slice(var.certificate_domain_names, 1, length(var.certificate_domain_names))) : []

  domain_name              = each.key
  regional_certificate_arn = aws_acm_certificate_validation.maintenance_api_cert.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.tags
}

resource "aws_api_gateway_base_path_mapping" "public_domain" {
  for_each = length(var.certificate_domain_names) > 1 ? toset(slice(var.certificate_domain_names, 1, length(var.certificate_domain_names))) : toset([])

  domain_name = each.key
  api_id      = aws_api_gateway_rest_api.restapi.id
  stage_name  = aws_api_gateway_stage.restapi.stage_name
}

/********************************************** method: ANY **************************************************************************/
/*
resource "aws_api_gateway_method" "ANY" {
  rest_api_id      = aws_api_gateway_rest_api.restapi.id
  resource_id      = data.aws_api_gateway_resource.restapi.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "ANY" {
  depends_on = [aws_api_gateway_method.ANY]

  type                 = "MOCK"
  passthrough_behavior = "NEVER"
  rest_api_id          = aws_api_gateway_rest_api.restapi.id
  resource_id          = data.aws_api_gateway_resource.restapi.id
  http_method          = aws_api_gateway_method.ANY.http_method
  request_templates = {
    "application/json" = <<-EOT
      #if( $stageVariables.maintenance == "${local.maintenance_on}" )
      statusCode: 503
      #else
      statusCode: 200
      #end
    }
    EOT
  }
  timeout_milliseconds = 29000
}

resource "aws_api_gateway_integration_response" "ANY_response_200" {
  depends_on = [aws_api_gateway_integration.ANY]

  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = data.aws_api_gateway_resource.restapi.id
  http_method         = aws_api_gateway_method.ANY.http_method
  response_parameters = local.cors_integration_response_parameters
  response_templates  = { "application/json" = "" }
  selection_pattern   = "200"
  status_code         = "200"
}

resource "aws_api_gateway_method_response" "ANY_response_200" {
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = data.aws_api_gateway_resource.restapi.id
  http_method         = aws_api_gateway_method.ANY.http_method
  status_code         = aws_api_gateway_integration_response.ANY_response_200.status_code
  response_parameters = local.cors_method_response_parameters
}

resource "aws_api_gateway_integration_response" "ANY_response_503" {
  depends_on = [aws_api_gateway_integration.ANY]

  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.ANY.http_method
  response_parameters = local.cors_integration_response_parameters
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  status_code         = "503"
}

resource "aws_api_gateway_method_response" "ANY_response_503" {
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.ANY.http_method
  response_parameters = local.cors_method_response_parameters
  response_models     = { "application/json" = "Empty" }
  status_code         = "503"
}
*/

/********************************************** method: OPTIONS **************************************************************************/

resource "aws_api_gateway_method" "options" {
  rest_api_id      = aws_api_gateway_rest_api.restapi.id
  resource_id      = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "options" {
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  rest_api_id          = aws_api_gateway_rest_api.restapi.id
  resource_id          = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method          = aws_api_gateway_method.options.http_method
  request_templates    = { "application/json" = jsonencode({ statusCode = 200 }) }
  timeout_milliseconds = 29000
}

resource "aws_api_gateway_integration_response" "options_response_200" {
  depends_on = [aws_api_gateway_integration.options]

  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.options.http_method
  response_parameters = local.cors_integration_response_parameters
  status_code         = "200"
}

resource "aws_api_gateway_method_response" "options_response_200" {
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.options.http_method
  response_parameters = local.cors_method_response_parameters
  response_models     = { "application/json" = "Empty" }
  status_code         = "200"
}



/********************************************** method: GET **************************************************************************/

resource "aws_api_gateway_method" "get" {
  rest_api_id      = aws_api_gateway_rest_api.restapi.id
  resource_id      = data.aws_api_gateway_resource.restapi.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
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
  response_templates = {
    "text/html" = templatefile("${path.module}/index.html", var.template)
  }
}

resource "aws_api_gateway_method_response" "get_response_503" {
  rest_api_id         = aws_api_gateway_rest_api.restapi.id
  resource_id         = aws_api_gateway_rest_api.restapi.root_resource_id
  http_method         = aws_api_gateway_method.get.http_method
  response_parameters = local.cors_method_response_parameters
  status_code         = "503"
  response_models     = { "text/html" = "Empty" }
}
