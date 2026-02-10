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
| `duration`       | The duration of the AWS session in seconds.    | `false`  | `3600`         | Between 900 and 43200 seconds  |

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

## Troubleshooting

### Error: "Failed to assume AWS role"

**Causes**:
- The IAM role doesn't exist
- The OIDC trust policy doesn't allow your pipeline
- Network connectivity issues

**Solutions**:
1. Verify the role exists: `arn:aws:iam::{account-id}:role/bk-{hash}-role`
2. Check the role's trust policy includes your Buildkite organization
3. Ensure the role has appropriate permissions
4. Verify network connectivity to AWS STS

### Error: "Invalid AWS account ID"

**Cause**: The account ID is not a 12-digit number.

**Solution**: Provide a valid AWS account ID (e.g., `123456789012`).


## Security Features

This plugin implements several security best practices:

- **No hardcoded secrets**: Uses OIDC token authentication
- **Automatic secret redaction**: All tokens and credentials are redacted from Buildkite logs
- **Input validation**: Validates all configuration parameters
- **Sanitized error messages**: Error output never exposes credentials
- **Least privilege**: Runs in non-root container

## Development

Run tests:
```bash
make test
```

Run linting:
```bash
make plugin-lint
make shellcheck
```
