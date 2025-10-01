# Authenticate to AWS from Buildkite

[![usages](https://img.shields.io/badge/usages-white?logo=buildkite&logoColor=blue)](https://github.com/search?q=elastic%2Foblt-aws-auth+%28path%3A.buildkite%29&type=code)

This is an opinionated plugin to authenticate to the observability AWS accounts from Buildkite using an [AWS OIDC Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html).

## Properties

| Name             | Description                                    | Required | Default        |
|------------------|------------------------------------------------|----------|----------------|
| `aws-account-id` | The AWS account belonging to the assumed role. | `false`  | `697149045717` |
| `duration`       | The duration of the AWS session in seconds.    | `false`  | `3600`         |

## Usage

```yml
steps:
  - command: |
      aws sts get-caller-identity
    plugins:
      - elastic/oblt-aws-auth#v0.1.0:
          aws-account-id: 697149045717
          duration: 3600 # seconds
```
