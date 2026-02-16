#!/usr/bin/env bash

set -euo pipefail

echo "--- :aws: Verifying AWS credentials are set"

failed=0
for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
  if [ -z "${!var:-}" ]; then
    echo "Error: ${var} is not set. Plugin did not export credentials."
    failed=1
  else
    echo "${var} is set"
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "^^^ +++"
  echo "Plugin failed to export AWS credentials."
  exit 1
fi

echo "--- :aws: Verifying AWS credentials are valid"

if command -v aws &> /dev/null; then
  identity=$(aws sts get-caller-identity --output json)
  echo "Authenticated as:"
  echo "${identity}" | jq .
else
  echo "AWS CLI not available, using curl to verify credentials"
  # Use STS GetCallerIdentity via curl with AWS SigV4
  response=$(curl -sS --fail-with-body \
    --aws-sigv4 "aws:amz:us-east-1:sts" \
    --user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" \
    -H "X-Amz-Security-Token: ${AWS_SESSION_TOKEN}" \
    -H "Accept: application/json" \
    -d "Action=GetCallerIdentity&Version=2011-06-15" \
    "https://sts.amazonaws.com") || {
      echo "^^^ +++"
      echo "Failed to call AWS STS GetCallerIdentity"
      echo "${response}"
      exit 1
    }
  echo "Authenticated as:"
  echo "${response}" | jq .
fi

echo ""
echo "E2E test passed!"
