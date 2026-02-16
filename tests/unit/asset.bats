#!/usr/bin/env bats

setup() {
    load "${BATS_PLUGIN_PATH}/load.bash"

    export BUILDKITE_REPO="git@github.com:elastic/test-repo.git"
    export BUILDKITE_PIPELINE_SLUG="my-pipeline"
    export BUILDKITE_BUILD_NUMBER="123"
}

@test "Successfully assumes AWS role with valid credentials" {
    # arrange
    export BUILDKITE_PLUGIN_OBLT_AWS_AUTH_AWS_ACCOUNT_ID="697149045717"
    export BUILDKITE_PLUGIN_OBLT_AWS_AUTH_DURATION="3600"
    
    stub buildkite-agent \
        "oidc request-token --audience sts.amazonaws.com : echo 'test-oidc-token'" \
        "redactor add test-oidc-token : true" \
        "redactor add * : true" \
        "redactor add * : true" \
        "redactor add * : true"
    
    stub curl "cat $PWD/tests/fixtures/success.json"

    # act
    run bash -c "source $PWD/hooks/pre-command && echo AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID"

    # assert
    assert_success
    assert_output --partial "Successfully authenticated to AWS account"
    assert_output --partial "AWS_ACCESS_KEY_ID=ASgeIAIOSFODNN7EXAMPLE/AccessKeyId"
}

@test "Fails with clear error message when AWS role assumption fails" {
    # arrange
    stub buildkite-agent \
        "oidc request-token --audience sts.amazonaws.com : echo 'test-oidc-token'" \
        "redactor add test-oidc-token : true"
    
    stub curl "cat $PWD/tests/fixtures/errors.json"

    # act
    run $PWD/hooks/pre-command

    # assert
    assert_failure
    assert_output --partial "Error: Failed to assume AWS role"
    assert_output --partial "ValidationError"
    assert_output --partial "DurationSeconds exceeds the MaxSessionDuration"
    assert_output --partial "Troubleshooting:"
}

@test "Rejects invalid AWS account ID (too short)" {
    # arrange
    export BUILDKITE_PLUGIN_OBLT_AWS_AUTH_AWS_ACCOUNT_ID="12345"

    # act
    run $PWD/hooks/pre-command

    # assert
    assert_failure
    assert_output --partial "Error: Invalid AWS account ID"
    assert_output --partial "Must be a 12-digit number"
}

@test "Rejects invalid AWS account ID (contains letters)" {
    # arrange
    export BUILDKITE_PLUGIN_OBLT_AWS_AUTH_AWS_ACCOUNT_ID="12345678901a"

    # act
    run $PWD/hooks/pre-command

    # assert
    assert_failure
    assert_output --partial "Error: Invalid AWS account ID"
}

@test "Rejects duration below minimum (negative seconds)" {
    # arrange
    export BUILDKITE_PLUGIN_OBLT_AWS_AUTH_DURATION="-1"

    # act
    run $PWD/hooks/pre-command

    # assert
    assert_failure
    assert_output --partial "Error: Invalid duration"
    assert_output --partial "Must be positive"
}


@test "Rejects non-numeric duration" {
    # arrange
    export BUILDKITE_PLUGIN_OBLT_AWS_AUTH_DURATION="abc"

    # act
    run $PWD/hooks/pre-command

    # assert
    assert_failure
    assert_output --partial "Error: Invalid duration"
}

@test "Uses default values when parameters not provided" {
    # arrange - no parameters set
    stub buildkite-agent \
        "oidc request-token --audience sts.amazonaws.com : echo 'test-oidc-token'" \
        "redactor add test-oidc-token : true" \
        "redactor add * : true" \
        "redactor add * : true" \
        "redactor add * : true"
    
    stub curl "cat $PWD/tests/fixtures/success.json"

    # act
    run $PWD/hooks/pre-command

    # assert
    assert_success
    assert_output --partial "697149045717"
    assert_output --partial "3600s"
}
