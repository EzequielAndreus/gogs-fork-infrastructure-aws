//------------------------------------------------------------------------------
// Jenkinsfile - Infrastructure Provisioning Pipeline
// Runs Terragrunt commands directly, uses Terraform Cloud for state management
//------------------------------------------------------------------------------

// Load shared helper functions once at pipeline level
def helpers

pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        disableConcurrentBuilds()
    }

    environment {
        //----------------------------------------------------------------------
        // Terraform Cloud Configuration (State Backend Only)
        //----------------------------------------------------------------------
        TF_CLOUD_ORGANIZATION = credentials('tfc-organization')  // Your TF Cloud org name
        TF_TOKEN_app_terraform_io = credentials('tfc-api-token')  // TF Cloud API token for backend auth

        //----------------------------------------------------------------------
        // Terraform/Terragrunt Configuration
        //----------------------------------------------------------------------
        TERRAFORM_VERSION = '1.5.7'
        TERRAGRUNT_VERSION = '0.53.0'
        AWS_DEFAULT_REGION = 'us-east-1'  // Can be overridden per environment

        //----------------------------------------------------------------------
        // Environment Paths
        //----------------------------------------------------------------------
        STAGING_PATH = 'environments/us-east-1/staging'
        PRODUCTION_PATH = 'environments/us-east-1/production'

        //----------------------------------------------------------------------
        // Module Order (dependencies first)
        //----------------------------------------------------------------------
        MODULE_ORDER = 'vpc,secrets-manager,rds,ecs,ec2-splunk'

        //----------------------------------------------------------------------
        // Jira Configuration
        //----------------------------------------------------------------------
        JIRA_URL = 'https://equipo-1.atlassian.net'
        JIRA_PROJECT_KEY = 'PFM'
        JIRA_CREDS = credentials('jira-credentials')

        //----------------------------------------------------------------------
        // Discord Webhooks
        //----------------------------------------------------------------------
        DISCORD_WEBHOOK_STAGING = credentials('discord-webhook-staging')
        DISCORD_WEBHOOK_PRODUCTION = credentials('discord-webhook-production')

    }

    parameters {
        booleanParam(
            name: 'FORCE_APPLY_STAGING',
            defaultValue: false,
            description: 'Force apply staging changes without checking for changes'
        )
        booleanParam(
            name: 'FORCE_APPLY_PRODUCTION',
            defaultValue: false,
            description: 'Force apply production changes without checking for changes'
        )
    }

    stages {
        //----------------------------------------------------------------------
        // Stage: Checkout
        //----------------------------------------------------------------------
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --pretty=format:"%H %s"'
            }
        }

        //----------------------------------------------------------------------
        // Stage: Setup
        //----------------------------------------------------------------------
        stage('Setup') {
            steps {
                script {
                    // Load helper functions once for entire pipeline
                    helpers = load 'jenkins/shared/pipeline-helpers.groovy'

                    echo '=========================================='
                    echo '  Infrastructure Provisioning Pipeline   '
                    echo '=========================================='
                    echo "Terraform Version: ${TERRAFORM_VERSION}"
                    echo "Terragrunt Version: ${TERRAGRUNT_VERSION}"
                    echo "TF Cloud Org: ${TF_CLOUD_ORGANIZATION}"
                    echo 'State Backend: Terraform Cloud (Remote)'
                    echo '=========================================='

                    // Install required tools
                    helpers.setupTools(TERRAFORM_VERSION, TERRAGRUNT_VERSION)
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage: Staging Environment
        //----------------------------------------------------------------------
        stage('Staging') {
            environment {
                ENVIRONMENT = 'staging'
                ENV_PATH = "${STAGING_PATH}"
                DISCORD_WEBHOOK = "${DISCORD_WEBHOOK_STAGING}"
            }
            stages {
                stage('Staging - Plan') {
                    steps {
                        script {
                            env.CURRENT_STAGE = 'Staging - Plan'
                            echo '🔍 Staging: Running Terragrunt plan...'

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'STARTED',
                                ENVIRONMENT,
                                'plan',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Planning infrastructure changes'
                            )

                            // Run terragrunt plan for all modules
                            def hasChanges = helpers.runTerragruntPlan(
                                ENV_PATH,
                                MODULE_ORDER
                            )

                            env.STAGING_HAS_CHANGES = hasChanges ? 'true' : 'false'

                            if (hasChanges) {
                                echo '✅ Staging: Changes detected, ready for apply'
                            } else {
                                echo 'ℹ️ Staging: No changes detected'
                            }
                        }
                    }
                }

                stage('Staging - Apply') {
                    when {
                        expression {
                            env.STAGING_HAS_CHANGES == 'true' || params.FORCE_APPLY_STAGING
                        }
                    }
                    steps {
                        script {
                            env.CURRENT_STAGE = 'Staging - Apply'
                            echo '🚀 Staging: Running Terragrunt apply...'

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'STARTED',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Applying infrastructure changes'
                            )

                            // Run terragrunt apply for all modules
                            helpers.runTerragruntApply(
                                ENV_PATH,
                                MODULE_ORDER
                            )

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'SUCCESS',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Infrastructure successfully deployed'
                            )
                        }
                    }
                }

                stage('Staging - No Changes') {
                    when {
                        expression {
                            env.STAGING_HAS_CHANGES == 'false' && !params.FORCE_APPLY_STAGING
                        }
                    }
                    steps {
                        script {
                            echo 'ℹ️ Staging: No infrastructure changes detected'
                            echo '📦 All modules are up-to-date'

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'SUCCESS',
                                ENVIRONMENT,
                                'plan',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'No infrastructure changes detected'
                            )
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage: Production Environment
        //----------------------------------------------------------------------
        stage('Production') {
            environment {
                ENVIRONMENT = 'production'
                ENV_PATH = "${PRODUCTION_PATH}"
                DISCORD_WEBHOOK = "${DISCORD_WEBHOOK_PRODUCTION}"
            }
            stages {
                stage('Production - Plan') {
                    steps {
                        script {
                            env.CURRENT_STAGE = 'Production - Plan'
                            echo '🔍 Production: Running Terragrunt plan...'

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'STARTED',
                                ENVIRONMENT,
                                'plan',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Planning infrastructure changes'
                            )

                            // Run terragrunt plan for all modules
                            def hasChanges = helpers.runTerragruntPlan(
                                ENV_PATH,
                                MODULE_ORDER
                            )

                            env.PRODUCTION_HAS_CHANGES = hasChanges ? 'true' : 'false'

                            if (hasChanges) {
                                echo '✅ Production: Changes detected, requires approval'
                            } else {
                                echo 'ℹ️ Production: No changes detected'
                            }
                        }
                    }
                }

                stage('Production - Approval') {
                    when {
                        expression {
                            env.PRODUCTION_HAS_CHANGES == 'true' || params.FORCE_APPLY_PRODUCTION
                        }
                    }
                    steps {
                        script {
                            env.CURRENT_STAGE = 'Production - Approval'

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'APPROVAL_REQUIRED',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Manual approval required to proceed'
                            )

                            timeout(time: 60, unit: 'MINUTES') {
                                input message: '🚦 Apply to Production?',
                                      ok: 'Deploy to Production',
                                      submitter: 'admin,deploy-team'
                            }
                        }
                    }
                }

                stage('Production - Apply') {
                    when {
                        expression {
                            env.PRODUCTION_HAS_CHANGES == 'true' || params.FORCE_APPLY_PRODUCTION
                        }
                    }
                    steps {
                        script {
                            env.CURRENT_STAGE = 'Production - Apply'
                            echo '🚀 Production: Running Terragrunt apply...'

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'STARTED',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Applying infrastructure changes'
                            )

                            // Run terragrunt apply for all modules
                            helpers.runTerragruntApply(
                                ENV_PATH,
                                MODULE_ORDER
                            )

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'SUCCESS',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Infrastructure successfully deployed'
                            )
                        }
                    }
                }

                stage('Production - No Changes') {
                    when {
                        expression {
                            env.PRODUCTION_HAS_CHANGES == 'false' && !params.FORCE_APPLY_PRODUCTION
                        }
                    }
                    steps {
                        script {
                            echo 'ℹ️ Production: No infrastructure changes detected'
                            echo '📦 All modules are up-to-date'

                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'SUCCESS',
                                ENVIRONMENT,
                                'plan',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'No infrastructure changes detected'
                            )
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
    // Post Actions
    //--------------------------------------------------------------------------
    post {
        success {
            script {
                echo '✅ Pipeline completed successfully!'
            }
        }

        failure {
            script {
                // Get error message (truncated to 2000 chars for Jira)
                def errorMessage = ''
                try {
                    def logs = currentBuild.rawBuild?.getLog(500)
                    if (logs) {
                        errorMessage = logs.join('\n')
                        if (errorMessage.length() > 2000) {
                            errorMessage = errorMessage.substring(0, 2000) + "\n...[truncated]"
                        }
                    }
                } catch (Exception e) {
                    errorMessage = "Could not retrieve logs: ${e.message}"
                }

                // Determine which environment failed
                def failedEnv = env.CURRENT_STAGE ?: 'Unknown'
                def webhook = failedEnv.toLowerCase().contains('production') ?
                             env.DISCORD_WEBHOOK_PRODUCTION : env.DISCORD_WEBHOOK_STAGING
                def environment = failedEnv.toLowerCase().contains('production') ?
                                 'production' : 'staging'

                // Send Discord notification
                helpers.sendDiscordNotification(
                    webhook,
                    'FAILURE',
                    environment,
                    'pipeline',
                    failedEnv,
                    env.BUILD_URL,
                    env.BUILD_NUMBER,
                    "Pipeline failed at stage: ${failedEnv}"
                )

                // Create Jira ticket
                try {
                    def ticketKey = helpers.createJiraTicket(
                        env.JIRA_URL,
                        env.JIRA_CREDS_USR,
                        env.JIRA_CREDS_PSW,
                        env.JIRA_PROJECT_KEY,
                        environment,
                        'pipeline',
                        failedEnv,
                        env.BUILD_URL,
                        errorMessage
                    )
                    echo "📋 Created Jira ticket: ${ticketKey}"
                } catch (Exception e) {
                    echo "⚠️ Failed to create Jira ticket: ${e.message}"
                }
            }
        }

        always {
            script {
                echo '======================================'
                echo '  Pipeline Execution Complete        '
                echo '======================================'
            }
        }
    }
}
