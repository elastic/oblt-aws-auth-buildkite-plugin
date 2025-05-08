FROM buildkite/plugin-tester:v4.1.1

# Create non-root user
RUN adduser --disabled-password --gecos "" plugin-tester
USER plugin-tester