# Jenkins Pipeline Integration Tests

This directory contains integration tests for the main Jenkinsfile pipeline using the [Jenkins Pipeline Unit](https://github.com/jenkinsci/JenkinsPipelineUnit) testing framework.

## Overview

The tests validate the infrastructure provisioning pipeline behavior including:

- Pipeline initialization and loading
- Stage execution flow
- Environment variable configuration
- Credential handling
- Plan change detection
- Conditional apply logic
- Discord notifications
- Jira ticket creation on failure
- Workspace cleanup

## Prerequisites

- **Java 11+**: Required for running Gradle and the test framework
- **Gradle 8.4+**: Build tool (wrapper included)

## Running Tests

### Using Gradle Wrapper (Recommended)

```bash
# Initialize Gradle wrapper (first time only)
cd test/jenkins
gradle wrapper

# Run all tests
./gradlew test

# Run with verbose output
./gradlew test --info

# Run only pipeline tests
./gradlew pipelineTest

# Clean and run
./gradlew clean test
```

### Using Gradle Directly

```bash
cd test/jenkins
gradle test
```

## Test Structure

```text
test/jenkins/
├── build.gradle                    # Gradle build configuration
├── JenkinsfilePipelineTest.groovy  # Main test class
└── README.md                       # This file
```

## Test Cases

| Test Name | Description |
| ------------------------------------- | ------------------------------------------------------- |
| `testPipelineLoadsSuccessfully` | Verifies the Jenkinsfile loads without errors |
| `testCheckoutStage` | Tests the SCM checkout stage execution |
| `testSetupToolsStage` | Verifies Terraform and Terragrunt installation |
| `testStagingNoChanges` | Tests staging behavior when no infrastructure changes |
| `testStagingWithChanges` | Tests staging apply when changes are detected |
| `testProductionRequiresApproval` | Verifies production requires manual approval |
| `testDiscordNotificationOnApplyStart` | Tests Discord notification on apply start |
| `testDiscordNotificationOnSuccess` | Tests Discord notification on successful apply |
| `testSummaryStage` | Verifies pipeline summary output |
| `testStagingEnvironmentVariables` | Tests staging environment variable configuration |
| `testProductionEnvironmentVariables` | Tests production environment variable configuration |
| `testJiraTicketCreatedOnFailure` | Verifies Jira ticket creation on pipeline failure |
| `testWorkspaceCleanup` | Tests workspace cleanup in post actions |
| `testConcurrentBuildsDisabled` | Verifies concurrent builds are disabled |
| `testBuildTimeout` | Tests build timeout configuration |
| `testTerraformVersion` | Verifies correct Terraform version |
| `testTerragruntVersion` | Verifies correct Terragrunt version |
| `testPlanDetectsAddChanges` | Tests detection of "to add" in plan output |
| `testPlanDetectsModifyChanges` | Tests detection of "to change" in plan output |
| `testPlanDetectsDestroyChanges` | Tests detection of "to destroy" in plan output |

## How Tests Work

### Jenkins Pipeline Unit Framework

The tests use the `jenkins-pipeline-unit` library which provides:

1. **BasePipelineTest**: Base class for pipeline tests
2. **Method Registration**: Mock Jenkins pipeline steps
3. **Call Stack Tracking**: Track method invocations
4. **Binding Variables**: Simulate Jenkins environment

### Mocking Strategy

```groovy
// Mock sh command
helper.registerAllowedMethod('sh', [String], { cmd ->
    if (cmd.contains('terragrunt run-all apply')) {
        // Simulate apply
    }
    return ''
})

// Mock credentials
helper.registerAllowedMethod('credentials', [String], { credId ->
    return "mocked-${credId}"
})

// Mock shared library
helper.registerAllowedMethod('load', [String], { path ->
    return new MockPipelineHelpers()
})
```

### MockPipelineHelpers

The `MockPipelineHelpers` class simulates the shared library functions:

- `setupTools()` - Mock tool installation
- `sendDiscordNotification()` - Mock Discord webhooks
- `createJiraTicket()` - Mock Jira API calls

## Test Output

Tests generate reports in:

```text
build/
├── reports/
│   └── tests/
│       └── test/
│           └── index.html    # HTML test report
└── test-results/
    └── test/
        └── *.xml             # JUnit XML reports
```

## Extending Tests

### Adding New Tests

```groovy
@Test
void testNewFeature() {
    // Setup mocks
    helper.registerAllowedMethod('sh', [String], { cmd ->
        // Mock behavior
    })
    
    // Load and run pipeline
    def script = loadScript('../../Jenkinsfile')
    script.call()
    
    // Assertions
    assertTrue(/* condition */)
    
    // Debug output
    printCallStack()
}
```

### Testing Failure Scenarios

```groovy
@Test
void testFailureScenario() {
    helper.registerAllowedMethod('sh', [String], { cmd ->
        if (cmd.contains('apply')) {
            throw new Exception('Simulated failure')
        }
    })
    
    try {
        def script = loadScript('../../Jenkinsfile')
        script.call()
        fail('Expected exception')
    } catch (Exception e) {
        // Verify error handling
    }
}
```

## CI/CD Integration

Add to GitHub Actions workflow:

```yaml
- name: Run Jenkins Pipeline Tests
  run: |
    cd test/jenkins
    ./gradlew test
```

Add to Jenkins pipeline:

```groovy
stage('Pipeline Tests') {
    steps {
        dir('test/jenkins') {
            sh './gradlew test'
        }
    }
    post {
        always {
            junit 'test/jenkins/build/test-results/**/*.xml'
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **Script not found**: Ensure `loadScript()` path is correct relative to test file
2. **Method not registered**: Add missing methods with `helper.registerAllowedMethod()`
3. **Binding variable missing**: Set required variables in `setUp()`

### Debug Mode

Enable verbose output:

```groovy
@Test
void testWithDebug() {
    helper.scriptRoots = ['test/jenkins', '.']
    // ... test code ...
    printCallStack()  // Print all method calls
}
```

## Resources

- [Jenkins Pipeline Unit GitHub](https://github.com/jenkinsci/JenkinsPipelineUnit)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Gradle Testing Documentation](https://docs.gradle.org/current/userguide/java_testing.html)
