# Terraform AWS Maintenance Mode API module

> Terraform modules which creates API Gateway resources on AWS.

![Terraform GitHub Actions](https://github.com/edithcare/terraform-aws-maintenance-mode-api/workflows/Terraform%20GitHub%20Actions/badge.svg)

## available features

- module creates a Maintenance Mode API on AWS through the AWS API Gateway and all necessary resource like custom domains in Route53. - It's possible to declare multiple different environments with specific endpoints and separate maintenance mode toggles.
- endpoint will return a HTTP status code 200 in case the maintenance mode is off, otherwise a 503 HTTP status code for all requests.

## requirements

* A domain managed by AWS Route53

## usage
```hcl
module "maintenance_api" {
  source  = "app.terraform.io/edithcare/maintenance-mode-api/aws"
  version = "0.1.0"

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

## conditional creation
..

# examples
- [simple](examples/simple): simple usage ..


## documentation

Terraform documentation is generated automatically using [pre-commit hooks](http://www.pre-commit.com/). Follow installation instructions [here](https://pre-commit.com/#install).

## requirements


## providers

..

## modules

No modules.

## resources

## inputs

Please see the [variables.tf](variables.tf) file

## outputs

Please see the [output.tf](output.tf) file

## license

MIT Licensed. See [LICENSE](https://github.com/edithcare/terraform-aws-maintenance-mode-api/blob/master/LICENSE) for full details.
