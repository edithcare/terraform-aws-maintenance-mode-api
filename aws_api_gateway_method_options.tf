resource "aws_api_gateway_method" "maintenance_api_options" {
  rest_api_id      = aws_api_gateway_rest_api.maintenance_api.id
  resource_id      = data.aws_api_gateway_resource.maintenance_api.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "maintenance_api_options" {
  rest_api_id          = aws_api_gateway_rest_api.maintenance_api.id
  resource_id          = data.aws_api_gateway_resource.maintenance_api.id
  http_method          = aws_api_gateway_method.maintenance_api_options.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_parameters   = {}
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
  timeout_milliseconds = 29000
}

resource "aws_api_gateway_integration_response" "maintenance_api_options_response_200" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api_options.http_method
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  response_templates = {
    "application/json" = ""
  }
  status_code = "200"
}

resource "aws_api_gateway_method_response" "maintenance_api_options_response_200" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api_options.http_method
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false # why false ?
    "method.response.header.Access-Control-Allow-Methods" = false # why false ?
    "method.response.header.Access-Control-Allow-Origin"  = false # why false ?
  }
  status_code = aws_api_gateway_integration_response.maintenance_api_options_response_200.status_code
}
