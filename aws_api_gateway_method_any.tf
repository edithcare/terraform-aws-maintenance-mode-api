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
    "application/json" = <<-EOT
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
  status_code       = "200"
}

resource "aws_api_gateway_method_response" "maintenance_api_response_200" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api.http_method
  status_code = aws_api_gateway_integration_response.maintenance_api_response_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_integration_response" "maintenance_api_response_503" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api.http_method
  status_code = "503"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_method_response" "maintenance_api_response_503" {
  rest_api_id = aws_api_gateway_rest_api.maintenance_api.id
  resource_id = data.aws_api_gateway_resource.maintenance_api.id
  http_method = aws_api_gateway_method.maintenance_api.http_method
  status_code = aws_api_gateway_integration_response.maintenance_api_response_503.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
