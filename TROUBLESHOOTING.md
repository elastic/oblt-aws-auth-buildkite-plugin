
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
