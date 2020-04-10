
# Terraform AWS Maintenance Mode API

![Terraform GitHub Actions](https://github.com/edithcare/terraform-aws-maintenance-mode-api/workflows/Terraform%20GitHub%20Actions/badge.svg)

This terraform module creates a Maintenance Mode API on AWS through the AWS API Gateway and all necessary resource like custom domains in Route 53. It's possible to declare multiple different environments with specific endpoints and separate maintenance mode toggles. An endpoint will return a HTTP status code 200 in case the maintenance mode is off, otherwise a 503 HTTP status code for all requests.

## Requirements

* A domain managed by AWS Route53

## Example

```hcl

module "maintenance_api" {
  source = "terraform-aws-maintenance-mode-api"

  zone_name                = "test.com."
  maintenance_api_name     = "Maintenance API"
  certificate_domain_names = ["test-maintenance-api.test.com", "test-maintenance-api-dev.test.com"]

  environments = {
    "dev"  = "test-maintenance-api-dev.test.com"
    "prod" = "test-maintenance-api.test.com"
  }

  maintenance_modes = {
    "dev"  = true
    "prod" = false
  }
}

```


## Inputs

Please see the [variables.tf](variables.tf) file

## Outputs

Please see the [output.tf](output.tf) file
