# Terraform Module Tests

This directory contains unit tests for all Terraform modules in this repository using [Terratest](https://terratest.gruntwork.io/).

## Prerequisites

- Go 1.21 or later
- Terraform 1.5.7 or later
- AWS credentials configured (for integration tests)

## Test Structure

```
test/
├── go.mod                    # Go module definition
├── doc.go                    # Package documentation
├── vpc_test.go               # VPC module tests
├── ecs_test.go               # ECS module tests
├── rds_test.go               # RDS module tests
├── ec2_splunk_test.go        # EC2-Splunk module tests
├── secrets_manager_test.go   # Secrets Manager module tests
└── jenkins/                  # Jenkins pipeline integration tests
    ├── build.gradle                    # Gradle build configuration
    ├── JenkinsfilePipelineTest.groovy  # Pipeline integration tests
    └── README.md                       # Jenkins test documentation
```

## Running Tests

### Install Dependencies

```bash
cd test
go mod download
```

### Run All Tests

```bash
go test -v -timeout 30m
```

### Run Tests for a Specific Module

```bash
# VPC module tests
go test -v -run TestVpc -timeout 10m

# ECS module tests
go test -v -run TestEcs -timeout 10m

# RDS module tests
go test -v -run TestRds -timeout 10m

# EC2-Splunk module tests
go test -v -run TestEc2Splunk -timeout 10m

# Secrets Manager module tests
go test -v -run TestSecretsManager -timeout 10m
```

### Run a Specific Test

```bash
go test -v -run TestVpcModuleVariablesValidation -timeout 5m
```

## Test Types

### Unit Tests (Current Implementation)

These tests validate:
- Terraform configuration syntax
- Variable validation
- Module structure
- Configuration combinations

Unit tests run `terraform init` and `terraform validate` without actually creating resources.

### Integration Tests (Future Enhancement)

For full integration testing that creates real AWS resources:

1. Configure AWS credentials
2. Uncomment the `terraform.Apply()` and `terraform.Destroy()` calls
3. Run with longer timeout: `go test -v -timeout 60m`

## Test Coverage

| Module | Tests | Coverage |
|--------|-------|----------|
| VPC | 4 | CIDR validation, NAT Gateway toggle, tagging |
| ECS | 4 | Container config, auto-scaling, Docker images |
| RDS | 5 | DB engines, instance classes, storage, production config |
| EC2-Splunk | 5 | Instance types, volumes, network, Splunk versions |
| Secrets Manager | 6 | Secret types, KMS, recovery window, app secrets |

## Writing New Tests

### Template

```go
func TestModuleNewFeature(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/module-name",
        Vars: map[string]interface{}{
            "variable_name": "value",
        },
        NoColor: true,
    })

    // Validate configuration
    terraform.Init(t, terraformOptions)
    result := terraform.Validate(t, terraformOptions)
    assert.NotNil(t, result)
}
```

### Best Practices

1. **Use `t.Parallel()`** - Run tests in parallel for faster execution
2. **Capture range variables** - Use `tc := tc` in loops to avoid race conditions
3. **Provide meaningful names** - Use descriptive test case names
4. **Test edge cases** - Include boundary conditions and error cases
5. **Clean up resources** - Always use `defer terraform.Destroy()` for integration tests

## CI Integration

Tests are automatically run in the CI pipeline. See `.github/workflows/ci.yml` for configuration.

### GitHub Actions Example

```yaml
- name: Run Terraform Module Tests
  run: |
    cd test
    go mod download
    go test -v -timeout 30m

- name: Run Jenkins Pipeline Tests
  run: |
    cd test/jenkins
    ./gradlew test
```

## Jenkins Pipeline Tests

In addition to Terraform module tests, this directory includes integration tests for the Jenkins pipeline.

See [jenkins/README.md](jenkins/README.md) for details on:
- Running pipeline tests with Gradle
- Test cases for pipeline stages
- Mocking Jenkins steps and shared libraries

### Quick Start

```bash
cd test/jenkins
gradle wrapper
./gradlew test
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "terraform not found" | Ensure Terraform is installed and in PATH |
| "module not found" | Check TerraformDir path is correct |
| "variable required" | Add missing required variables to test Vars |
| "timeout" | Increase timeout with `-timeout` flag |

### Debug Mode

Run with debug logging:

```bash
TF_LOG=DEBUG go test -v -run TestVpcModuleVariablesValidation
```
