# Authenticate to AWS from Buildkite

[![usages](https://img.shields.io/badge/usages-white?logo=buildkite&logoColor=blue)](https://github.com/search?q=elastic%2Foblt-aws-auth+%28path%3A.buildkite%29&type=code)

This is an opinionated plugin to authenticate to the observability AWS accounts from Buildkite using an [AWS OIDC Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html).

## Prerequisites

This plugin requires:
- An AWS OIDC Provider configured in your AWS account
- An IAM role with a trust policy that allows your Buildkite pipeline
- The role name must follow the pattern: `bk-{hash}-role` where the hash is generated from your repository and pipeline slug
- Buildkite agent with OIDC token support

See the [Elastic OBLT Infrastructure](https://github.com/elastic/oblt-infra/blob/main/modules/aws-buildkite-oidc/main.tf) for the Terraform setup.

## How It Works

The plugin:
1. Generates a unique hash from your repository and pipeline slug
2. Constructs the IAM role ARN using this hash: `arn:aws:iam::{account-id}:role/bk-{hash}-role`
3. Requests an OIDC token from Buildkite
4. Uses the token to assume the AWS role via `AssumeRoleWithWebIdentity`
5. Exports AWS credentials as environment variables
6. Automatically redacts all secrets from logs

## Properties

| Name             | Description                                    | Required | Default        | Constraints                    |
|------------------|------------------------------------------------|----------|----------------|--------------------------------|
| `aws-account-id` | The AWS account belonging to the assumed role. | `false`  | `697149045717` | Must be a 12-digit number      |
| `duration`       | The duration of the AWS session in seconds.    | `false`  | `3600`         | Positive. Max is defined in `MaxSessionDuration` role's property  |

## Usage

### Basic Usage

```yml
steps:
  - command: |
      aws sts get-caller-identity
    plugins:
      - elastic/oblt-aws-auth#v0.1.0:
          aws-account-id: 697149045717
          duration: 3600 # seconds
```

### Using Default Values

```yml
steps:
  - command: |
      # Automatically uses default account ID and 1-hour duration
      aws s3 ls
    plugins:
      - elastic/oblt-aws-auth#v0.1.0
```

### Extended Session Duration

```yml
steps:
  - command: |
      # Long-running job with 12-hour session
      ./deploy.sh
    plugins:
      - elastic/oblt-aws-auth#v0.1.0:
          duration: 43200 # 12 hours
```

