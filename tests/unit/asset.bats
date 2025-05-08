#!/usr/bin/env bats

setup() {
    load "${BATS_PLUGIN_PATH}/load.bash"

    export BUILDKITE_REPO="elastic/repo"
    export BUILDKITE_PIPELINE_SLUG="my-pipeline"
    export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_WITH_WEB_IDENTITY_ROLE_ARN="role123"
}

@test "failure to get token" {
    # arrange
    stub buildkite-agent "oidc request-token --audience sts.amazonaws.com * : echo 'buildkite-oidc-token'"
    stub curl "cat $PWD/tests/fixtures/errors.json"

    # act
    run $PWD/hooks/pre-command

    # assert
    assert_failure
}
