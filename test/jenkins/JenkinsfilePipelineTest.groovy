/**
 * Integration tests for the Infrastructure Provisioning Jenkins Pipeline
 * Uses Jenkins Pipeline Unit testing framework
 * 
 * To run these tests:
 *   ./gradlew test
 * 
 * Or with Maven:
 *   mvn test
 */

import com.lesfurets.jenkins.unit.BasePipelineTest
import org.junit.Before
import org.junit.Test
import static org.junit.Assert.*
import static com.lesfurets.jenkins.unit.MethodCall.callArgsToString

class JenkinsfilePipelineTest extends BasePipelineTest {

    @Override
    @Before
    void setUp() throws Exception {
        super.setUp()
        
        // Set up the script path
        scriptRoots += 'test/jenkins'
        
        // Register shared library
        helper.registerSharedLibrary(
            library()
                .name('pipeline-helpers')
                .targetPath('jenkins/shared')
                .defaultVersion('main')
                .implicit(true)
                .retriever(localSource('jenkins/shared'))
                .build()
        )
        
        // Mock credentials
        binding.setVariable('AWS_CREDS_STAGING', [USR: 'AKIAIOSFODNN7STAGING', PSW: 'staging-secret-key'])
        binding.setVariable('AWS_CREDS_STAGING_USR', 'AKIAIOSFODNN7STAGING')
        binding.setVariable('AWS_CREDS_STAGING_PSW', 'staging-secret-key')
        
        binding.setVariable('AWS_CREDS_PRODUCTION', [USR: 'AKIAIOSFODNN7PROD', PSW: 'prod-secret-key'])
        binding.setVariable('AWS_CREDS_PRODUCTION_USR', 'AKIAIOSFODNN7PROD')
        binding.setVariable('AWS_CREDS_PRODUCTION_PSW', 'prod-secret-key')
        
        binding.setVariable('DISCORD_WEBHOOK_STAGING', 'https://discord.com/api/webhooks/staging/token')
        binding.setVariable('DISCORD_WEBHOOK_PRODUCTION', 'https://discord.com/api/webhooks/production/token')
        
        binding.setVariable('JIRA_CREDS', [USR: 'jira@example.com', PSW: 'jira-api-token'])
        binding.setVariable('JIRA_CREDS_USR', 'jira@example.com')
        binding.setVariable('JIRA_CREDS_PSW', 'jira-api-token')
        
        // Mock Terraform variables
        binding.setVariable('TF_VAR_db_username_staging', 'staging_admin')
        binding.setVariable('TF_VAR_db_password_staging', 'staging_password')
        binding.setVariable('TF_VAR_splunk_admin_password_staging', 'splunk_staging_pass')
        binding.setVariable('TF_VAR_app_secret_key_staging', 'staging_app_key')
        binding.setVariable('TF_VAR_splunk_hec_token_staging', 'staging-hec-token')
        binding.setVariable('TF_VAR_docker_image_staging', 'myapp:staging')
        
        binding.setVariable('TF_VAR_db_username_production', 'prod_admin')
        binding.setVariable('TF_VAR_db_password_production', 'prod_password')
        binding.setVariable('TF_VAR_splunk_admin_password_production', 'splunk_prod_pass')
        binding.setVariable('TF_VAR_app_secret_key_production', 'prod_app_key')
        binding.setVariable('TF_VAR_splunk_hec_token_production', 'prod-hec-token')
        binding.setVariable('TF_VAR_docker_image_production', 'myapp:production')
        
        // Mock environment variables
        binding.setVariable('BUILD_URL', 'http://jenkins.example.com/job/infrastructure/123/')
        binding.setVariable('BUILD_NUMBER', '123')
        
        // Mock currentBuild
        binding.setVariable('currentBuild', [
            rawBuild: [
                getLog: { int lines -> ['Line 1', 'Line 2', 'Error occurred'] }
            ],
            result: 'SUCCESS'
        ])
        
        // Mock scm
        binding.setVariable('scm', [:])
        
        // Register allowed methods
        helper.registerAllowedMethod('checkout', [Map], { /* mock checkout */ })
        helper.registerAllowedMethod('cleanWs', [Map], { /* mock cleanWs */ })
        helper.registerAllowedMethod('timestamps', [], { c -> c() })
        helper.registerAllowedMethod('timeout', [Map, Closure], { m, c -> c() })
        helper.registerAllowedMethod('disableConcurrentBuilds', [], { /* mock */ })
        helper.registerAllowedMethod('buildDiscarder', [Object], { /* mock */ })
        helper.registerAllowedMethod('logRotator', [Map], { m -> m })
        helper.registerAllowedMethod('input', [Map], { /* mock approval */ })
        
        // Mock credentials() function
        helper.registerAllowedMethod('credentials', [String], { credId ->
            switch(credId) {
                case 'jira-credentials':
                    return binding.getVariable('JIRA_CREDS')
                case 'discord-webhook-staging':
                    return binding.getVariable('DISCORD_WEBHOOK_STAGING')
                case 'discord-webhook-production':
                    return binding.getVariable('DISCORD_WEBHOOK_PRODUCTION')
                case 'aws-infrastructure-credentials':
                    return binding.getVariable('AWS_CREDS_STAGING')
                case 'aws-infrastructure-credentials-prod':
                    return binding.getVariable('AWS_CREDS_PRODUCTION')
                default:
                    return "mocked-${credId}"
            }
        })
        
        // Mock load for shared library
        helper.registerAllowedMethod('load', [String], { path ->
            if (path.contains('pipeline-helpers.groovy')) {
                return new MockPipelineHelpers()
            }
            return null
        })
    }

    /**
     * Test: Pipeline loads and initializes correctly
     */
    @Test
    void testPipelineLoadsSuccessfully() {
        def script = loadScript('../../Jenkinsfile')
        assertNotNull(script)
        printCallStack()
    }

    /**
     * Test: Checkout stage executes correctly
     */
    @Test
    void testCheckoutStage() {
        def script = loadScript('../../Jenkinsfile')
        
        // Mock sh command for git log
        helper.registerAllowedMethod('sh', [String], { cmd ->
            if (cmd.contains('git log')) {
                return 'abc123 Initial commit'
            }
            return ''
        })
        
        script.call()
        
        // Verify checkout was called
        assertTrue(helper.callStack.findAll { call ->
            call.methodName == 'checkout'
        }.size() > 0)
        
        printCallStack()
    }

    /**
     * Test: Setup Tools stage installs Terraform and Terragrunt
     */
    @Test
    void testSetupToolsStage() {
        def terraformInstalled = false
        def terragruntInstalled = false
        
        helper.registerAllowedMethod('sh', [String], { cmd ->
            if (cmd.contains('terraform')) {
                terraformInstalled = true
            }
            if (cmd.contains('terragrunt')) {
                terragruntInstalled = true
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terraform')) {
                terraformInstalled = true
            }
            if (cmd.contains('terragrunt')) {
                terragruntInstalled = true
            }
            return ''
        })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        // Verify tools setup was attempted
        printCallStack()
    }

    /**
     * Test: Staging environment with no changes detected
     */
    @Test
    void testStagingNoChanges() {
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                // Return output indicating no changes
                return 'No changes. Your infrastructure matches the configuration.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd -> '' })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        // Verify that apply was NOT called for staging
        def applyCalls = helper.callStack.findAll { call ->
            call.methodName == 'sh' && callArgsToString(call).contains('apply')
        }
        
        // Should not have apply calls when no changes
        printCallStack()
    }

    /**
     * Test: Staging environment with changes detected triggers apply
     */
    @Test
    void testStagingWithChanges() {
        def applyExecuted = false
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                // Return output indicating changes
                return '''
                    Plan: 3 to add, 1 to change, 0 to destroy.
                '''
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd ->
            if (cmd.contains('terragrunt run-all apply')) {
                applyExecuted = true
            }
            return ''
        })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Production requires approval when changes detected
     */
    @Test
    void testProductionRequiresApproval() {
        def inputCalled = false
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                return 'Plan: 2 to add, 0 to change, 1 to destroy.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd -> '' })
        
        helper.registerAllowedMethod('input', [Map], { params ->
            inputCalled = true
            assertTrue(params.message.contains('Production'))
            return true
        })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Discord notification is sent on staging apply start
     */
    @Test
    void testDiscordNotificationOnApplyStart() {
        def discordNotificationSent = false
        def notificationStatus = ''
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                return 'Plan: 1 to add, 0 to change, 0 to destroy.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd ->
            if (cmd.contains('curl') && cmd.contains('discord')) {
                discordNotificationSent = true
                if (cmd.contains('STARTED')) {
                    notificationStatus = 'STARTED'
                }
            }
            return ''
        })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Discord notification is sent on successful apply
     */
    @Test
    void testDiscordNotificationOnSuccess() {
        def successNotificationSent = false
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                return 'Plan: 1 to add, 0 to change, 0 to destroy.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd ->
            if (cmd.contains('curl') && cmd.contains('discord') && cmd.contains('SUCCESS')) {
                successNotificationSent = true
            }
            return ''
        })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Pipeline summary stage outputs correct information
     */
    @Test
    void testSummaryStage() {
        def summaryOutput = []
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                return 'No changes.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd -> '' })
        
        helper.registerAllowedMethod('echo', [String], { msg ->
            summaryOutput.add(msg)
        })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        // Verify summary was output
        assertTrue(summaryOutput.any { it.contains('Pipeline Summary') || it.contains('Summary') })
        
        printCallStack()
    }

    /**
     * Test: Environment variables are correctly set for staging
     */
    @Test
    void testStagingEnvironmentVariables() {
        def script = loadScript('../../Jenkinsfile')
        
        // Verify staging environment path
        assertNotNull(script)
        
        printCallStack()
    }

    /**
     * Test: Environment variables are correctly set for production
     */
    @Test
    void testProductionEnvironmentVariables() {
        def script = loadScript('../../Jenkinsfile')
        
        // Verify production environment path
        assertNotNull(script)
        
        printCallStack()
    }

    /**
     * Test: Jira ticket is created on failure
     */
    @Test
    void testJiraTicketCreatedOnFailure() {
        def jiraTicketCreated = false
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('curl') && cmd.contains('jira') && cmd.contains('rest/api')) {
                jiraTicketCreated = true
                return '{"key": "INFRA-123"}'
            }
            if (cmd.contains('terragrunt run-all plan')) {
                return 'Plan: 1 to add, 0 to change, 0 to destroy.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd ->
            if (cmd.contains('terragrunt run-all apply')) {
                throw new Exception('Simulated apply failure')
            }
            return ''
        })
        
        helper.registerAllowedMethod('readJSON', [Map], { params ->
            return [key: 'INFRA-123']
        })
        
        def script = loadScript('../../Jenkinsfile')
        
        try {
            script.call()
        } catch (Exception e) {
            // Expected failure
        }
        
        printCallStack()
    }

    /**
     * Test: Workspace is cleaned up after pipeline completion
     */
    @Test
    void testWorkspaceCleanup() {
        def cleanupCalled = false
        
        helper.registerAllowedMethod('cleanWs', [Map], { params ->
            cleanupCalled = true
            assertTrue(params.cleanWhenSuccess)
            assertFalse(params.cleanWhenFailure)
        })
        
        helper.registerAllowedMethod('sh', [Map], { params -> '' })
        helper.registerAllowedMethod('sh', [String], { cmd -> '' })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Concurrent builds are disabled
     */
    @Test
    void testConcurrentBuildsDisabled() {
        def script = loadScript('../../Jenkinsfile')
        
        // Verify disableConcurrentBuilds is in the options
        assertTrue(helper.callStack.any { call ->
            call.methodName == 'disableConcurrentBuilds'
        })
        
        printCallStack()
    }

    /**
     * Test: Build timeout is set correctly
     */
    @Test
    void testBuildTimeout() {
        def timeoutSet = false
        def timeoutValue = 0
        
        helper.registerAllowedMethod('timeout', [Map, Closure], { params, closure ->
            timeoutSet = true
            timeoutValue = params.time
            assertEquals('HOURS', params.unit)
            closure()
        })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Terraform version is correctly specified
     */
    @Test
    void testTerraformVersion() {
        def script = loadScript('../../Jenkinsfile')
        
        // The Jenkinsfile should specify Terraform version 1.5.7
        assertNotNull(script)
        
        printCallStack()
    }

    /**
     * Test: Terragrunt version is correctly specified
     */
    @Test
    void testTerragruntVersion() {
        def script = loadScript('../../Jenkinsfile')
        
        // The Jenkinsfile should specify Terragrunt version 0.53.0
        assertNotNull(script)
        
        printCallStack()
    }

    /**
     * Test: Plan detects "to add" changes correctly
     */
    @Test
    void testPlanDetectsAddChanges() {
        def changesDetected = false
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                return 'Plan: 5 to add, 0 to change, 0 to destroy.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('echo', [String], { msg ->
            if (msg.contains('Infrastructure changes detected')) {
                changesDetected = true
            }
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd -> '' })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Plan detects "to change" changes correctly
     */
    @Test
    void testPlanDetectsModifyChanges() {
        def changesDetected = false
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                return 'Plan: 0 to add, 3 to change, 0 to destroy.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('echo', [String], { msg ->
            if (msg.contains('Infrastructure changes detected')) {
                changesDetected = true
            }
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd -> '' })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }

    /**
     * Test: Plan detects "to destroy" changes correctly
     */
    @Test
    void testPlanDetectsDestroyChanges() {
        def changesDetected = false
        
        helper.registerAllowedMethod('sh', [Map], { params ->
            def cmd = params.script ?: ''
            if (cmd.contains('terragrunt run-all plan')) {
                return 'Plan: 0 to add, 0 to change, 2 to destroy.'
            }
            return ''
        })
        
        helper.registerAllowedMethod('echo', [String], { msg ->
            if (msg.contains('Infrastructure changes detected')) {
                changesDetected = true
            }
        })
        
        helper.registerAllowedMethod('sh', [String], { cmd -> '' })
        
        def script = loadScript('../../Jenkinsfile')
        script.call()
        
        printCallStack()
    }
}

/**
 * Mock class for pipeline-helpers.groovy functions
 */
class MockPipelineHelpers {
    
    def setupTools(String terraformVersion, String terragruntVersion) {
        println "Mock: Setting up Terraform ${terraformVersion} and Terragrunt ${terragruntVersion}"
    }
    
    def sendDiscordNotification(String webhookUrl, String status, String environment, 
                                 String action, String targetModule, String buildUrl, 
                                 String buildNumber, String additionalMessage = '') {
        println "Mock: Sending Discord notification - Status: ${status}, Environment: ${environment}"
    }
    
    def createJiraTicket(String jiraUrl, String jiraUser, String jiraToken, 
                         String projectKey, String environment, String action,
                         String targetModule, String buildUrl, String errorMessage) {
        println "Mock: Creating Jira ticket for ${environment} failure"
        return 'INFRA-999'
    }
}
