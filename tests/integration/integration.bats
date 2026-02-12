#!/usr/bin/env bats

# Integration tests for the oblt-aws-auth plugin.
# These test the plugin script holistically: hash generation determinism,
# response parsing with various payloads, and full execution flows.

setup() {
    load "${BATS_PLUGIN_PATH}/load.bash"

    export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
    export BUILDKITE_PIPELINE_SLUG="my-pipeline"
    export BUILDKITE_BUILD_NUMBER="123"
}

# --- Hash generation ---

@test "Hash is deterministic for the same repo and pipeline" {
    hash1=$(echo -n "$(echo "${BUILDKITE_REPO}" | awk -F'[:.]' '{ printf $3 }')/${BUILDKITE_PIPELINE_SLUG}" | sha256sum | cut -c1-55)
    hash2=$(echo -n "$(echo "${BUILDKITE_REPO}" | awk -F'[:.]' '{ printf $3 }')/${BUILDKITE_PIPELINE_SLUG}" | sha256sum | cut -c1-55)

    [ "$hash1" = "$hash2" ]
}

@test "Hash differs for different repositories" {
    hash1=$(echo -n "$(echo "git@github.com:elastic/repo-a.git" | awk -F'[:.]' '{ printf $3 }')/my-pipeline" | sha256sum | cut -c1-55)
    hash2=$(echo -n "$(echo "git@github.com:elastic/repo-b.git" | awk -F'[:.]' '{ printf $3 }')/my-pipeline" | sha256sum | cut -c1-55)

    [ "$hash1" != "$hash2" ]
}

@test "Hash differs for different pipeline slugs" {
    hash1=$(echo -n "$(echo "${BUILDKITE_REPO}" | awk -F'[:.]' '{ printf $3 }')/pipeline-a" | sha256sum | cut -c1-55)
    hash2=$(echo -n "$(echo "${BUILDKITE_REPO}" | awk -F'[:.]' '{ printf $3 }')/pipeline-b" | sha256sum | cut -c1-55)

    [ "$hash1" != "$hash2" ]
}

@test "Hash is exactly 55 characters" {
    hash=$(echo -n "$(echo "${BUILDKITE_REPO}" | awk -F'[:.]' '{ printf $3 }')/${BUILDKITE_PIPELINE_SLUG}" | sha256sum | cut -c1-55)

    [ ${#hash} -eq 55 ]
}

@test "Hash handles HTTPS repository URLs" {
    export BUILDKITE_REPO="https://github.com/elastic/test-repo.git"

    hash=$(echo -n "$(echo "${BUILDKITE_REPO}" | awk -F'[:.]' '{ printf $3 }')/${BUILDKITE_PIPELINE_SLUG}" | sha256sum | cut -c1-55)

    # Should produce a valid 55-char hex string
    [ ${#hash} -eq 55 ]
    [[ "$hash" =~ ^[0-9a-f]+$ ]]
}

# --- Response parsing ---

@test "Parses credentials from a valid AWS STS response" {
    response=$(cat "$PWD/tests/fixtures/success.json")
    credentials_json_path=".AssumeRoleWithWebIdentityResponse.AssumeRoleWithWebIdentityResult.Credentials"

    access_key=$(echo "$response" | jq -r "${credentials_json_path}.AccessKeyId // \"\"")
    secret_key=$(echo "$response" | jq -r "${credentials_json_path}.SecretAccessKey // \"\"")
    session_token=$(echo "$response" | jq -r "${credentials_json_path}.SessionToken // \"\"")

    [ -n "$access_key" ]
    [ -n "$secret_key" ]
    [ -n "$session_token" ]
    [ "$access_key" != "null" ]
}

@test "Returns empty strings for error responses" {
    response=$(cat "$PWD/tests/fixtures/errors.json")
    credentials_json_path=".AssumeRoleWithWebIdentityResponse.AssumeRoleWithWebIdentityResult.Credentials"

    access_key=$(echo "$response" | jq -r "${credentials_json_path}.AccessKeyId // \"\"")
    secret_key=$(echo "$response" | jq -r "${credentials_json_path}.SecretAccessKey // \"\"")
    session_token=$(echo "$response" | jq -r "${credentials_json_path}.SessionToken // \"\"")

    [ -z "$access_key" ]
    [ -z "$secret_key" ]
    [ -z "$session_token" ]
}

@test "Extracts error code and message from error responses" {
    response=$(cat "$PWD/tests/fixtures/errors.json")

    error_code=$(echo "$response" | jq -r '.Error.Code // "Unknown"')
    error_message=$(echo "$response" | jq -r '.Error.Message // "Unknown error"')

    [ "$error_code" = "ValidationError" ]
    [[ "$error_message" == *"MaxSessionDuration"* ]]
}

@test "Handles malformed JSON response gracefully" {
    response="this is not json"
    credentials_json_path=".AssumeRoleWithWebIdentityResponse.AssumeRoleWithWebIdentityResult.Credentials"

    access_key=$(echo "$response" | jq -r "${credentials_json_path}.AccessKeyId // \"\"" 2>/dev/null || echo "")

    [ -z "$access_key" ]
}

@test "Handles empty response gracefully" {
    response=""
    credentials_json_path=".AssumeRoleWithWebIdentityResponse.AssumeRoleWithWebIdentityResult.Credentials"

    access_key=$(echo "$response" | jq -r "${credentials_json_path}.AccessKeyId // \"\"" 2>/dev/null || echo "")

    [ -z "$access_key" ]
}

# --- Full script execution ---

@test "Exports all three AWS credential variables on success" {
    stub buildkite-agent \
        "oidc request-token --audience sts.amazonaws.com : echo 'test-oidc-token'"

    stub curl "cat $PWD/tests/fixtures/success.json"

    run bash -c "source $PWD/hooks/pre-command && echo AKI=\$AWS_ACCESS_KEY_ID SKI=\$AWS_SECRET_ACCESS_KEY ST=\$AWS_SESSION_TOKEN"

    assert_success
    assert_output --partial "AKI=ASgeIAIOSFODNN7EXAMPLE/AccessKeyId"
    assert_output --partial "SKI=wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY/SecretAccessKey"
    assert_output --partial "ST=AQoDYXdzEE0a8ANXXXXXXXXNO1ewxE5TijQyp+IEXAMPLE/SessionToken"
}

@test "Exits with code 1 on failed role assumption" {
    stub buildkite-agent \
        "oidc request-token --audience sts.amazonaws.com : echo 'test-oidc-token'"

    stub curl "cat $PWD/tests/fixtures/errors.json"

    run $PWD/hooks/pre-command

    assert_failure
    assert_output --partial "Failed to assume AWS role"
}

@test "Constructs correct role ARN with default account ID" {
    stub buildkite-agent \
        "oidc request-token --audience sts.amazonaws.com : echo 'test-oidc-token'"

    stub curl "cat $PWD/tests/fixtures/success.json"

    run bash -c "source $PWD/hooks/pre-command"

    assert_success
    assert_output --partial "arn:aws:iam::697149045717:role/bk-"
}

@test "Constructs correct role ARN with custom account ID" {
    export BUILDKITE_PLUGIN_OBLT_AWS_AUTH_AWS_ACCOUNT_ID="123456789012"

    stub buildkite-agent \
        "oidc request-token --audience sts.amazonaws.com : echo 'test-oidc-token'"

    stub curl "cat $PWD/tests/fixtures/success.json"

    run bash -c "source $PWD/hooks/pre-command"

    assert_success
    assert_output --partial "arn:aws:iam::123456789012:role/bk-"
}
