//------------------------------------------------------------------------------
// Jenkinsfile - Infrastructure Provisioning Pipeline
// Automatically provisions/updates staging and production based on plan output
//------------------------------------------------------------------------------

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
        // Tool Versions
        //----------------------------------------------------------------------
        TERRAFORM_VERSION = '1.5.7'
        TERRAGRUNT_VERSION = '0.53.0'

        //----------------------------------------------------------------------
        // AWS Configuration
        //----------------------------------------------------------------------
        AWS_REGION = 'us-east-1'

        //----------------------------------------------------------------------
        // Jira Configuration
        //----------------------------------------------------------------------
        JIRA_URL = 'https://your-company.atlassian.net'
        JIRA_PROJECT_KEY = 'INFRA'
        JIRA_CREDS = credentials('jira-credentials')

        //----------------------------------------------------------------------
        // Discord Webhooks
        //----------------------------------------------------------------------
        DISCORD_WEBHOOK_STAGING = credentials('discord-webhook-staging')
        DISCORD_WEBHOOK_PRODUCTION = credentials('discord-webhook-production')

        //----------------------------------------------------------------------
        // AWS Credentials - Staging
        //----------------------------------------------------------------------
        AWS_CREDS_STAGING = credentials('aws-infrastructure-credentials')

        //----------------------------------------------------------------------
        // AWS Credentials - Production
        //----------------------------------------------------------------------
        AWS_CREDS_PRODUCTION = credentials('aws-infrastructure-credentials-prod')

        //----------------------------------------------------------------------
        // Terraform Variables - Staging
        //----------------------------------------------------------------------
        TF_VAR_db_username_staging = credentials('db-username-staging')
        TF_VAR_db_password_staging = credentials('db-password-staging')
        TF_VAR_splunk_admin_password_staging = credentials('splunk-admin-password-staging')
        TF_VAR_app_secret_key_staging = credentials('app-secret-key-staging')
        TF_VAR_splunk_hec_token_staging = credentials('splunk-hec-token-staging')
        TF_VAR_docker_image_staging = credentials('docker-image-staging')

        //----------------------------------------------------------------------
        // Terraform Variables - Production
        //----------------------------------------------------------------------
        TF_VAR_db_username_production = credentials('db-username-production')
        TF_VAR_db_password_production = credentials('db-password-production')
        TF_VAR_splunk_admin_password_production = credentials('splunk-admin-password-production')
        TF_VAR_app_secret_key_production = credentials('app-secret-key-production')
        TF_VAR_splunk_hec_token_production = credentials('splunk-hec-token-production')
        TF_VAR_docker_image_production = credentials('docker-image-production')
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
        // Stage: Setup Tools
        //----------------------------------------------------------------------
        stage('Setup Tools') {
            steps {
                script {
                    def helpers = load 'jenkins/shared/pipeline-helpers.groovy'
                    helpers.setupTools(TERRAFORM_VERSION, TERRAGRUNT_VERSION)
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage: Plan & Apply Staging
        //----------------------------------------------------------------------
        stage('Staging') {
            environment {
                ENVIRONMENT = 'staging'
                ENVIRONMENTS_PATH = 'environments/us-east-1/staging'
                // Map staging credentials to AWS and Terraform variables
                AWS_ACCESS_KEY_ID = "${AWS_CREDS_STAGING_USR}"
                AWS_SECRET_ACCESS_KEY = "${AWS_CREDS_STAGING_PSW}"
                TF_VAR_db_username = "${TF_VAR_db_username_staging}"
                TF_VAR_db_password = "${TF_VAR_db_password_staging}"
                TF_VAR_splunk_admin_password = "${TF_VAR_splunk_admin_password_staging}"
                TF_VAR_app_secret_key = "${TF_VAR_app_secret_key_staging}"
                TF_VAR_splunk_hec_token = "${TF_VAR_splunk_hec_token_staging}"
                TF_VAR_docker_image = "${TF_VAR_docker_image_staging}"
                DISCORD_WEBHOOK = "${DISCORD_WEBHOOK_STAGING}"
            }
            stages {
                stage('Staging - Init') {
                    steps {
                        dir("${ENVIRONMENTS_PATH}") {
                            sh 'terragrunt run-all init --terragrunt-non-interactive'
                        }
                    }
                }

                stage('Staging - Plan') {
                    steps {
                        dir("${ENVIRONMENTS_PATH}") {
                            script {
                                // Run plan and capture output to detect changes
                                def planOutput = sh(
                                    script: 'terragrunt run-all plan --terragrunt-non-interactive -detailed-exitcode -out=tfplan 2>&1 || true',
                                    returnStdout: true
                                ).trim()
                                
                                echo planOutput
                                
                                // Check if there are changes to apply
                                env.STAGING_HAS_CHANGES = planOutput.contains('Plan:') && 
                                    (planOutput.contains('to add') || 
                                     planOutput.contains('to change') || 
                                     planOutput.contains('to destroy'))
                                
                                if (env.STAGING_HAS_CHANGES == 'true') {
                                    echo "✅ Staging: Infrastructure changes detected"
                                } else {
                                    echo "ℹ️ Staging: No infrastructure changes detected"
                                }
                            }
                        }
                    }
                }

                stage('Staging - Apply') {
                    when {
                        expression { env.STAGING_HAS_CHANGES == 'true' }
                    }
                    steps {
                        script {
                            // Send Discord notification for apply start
                            def helpers = load 'jenkins/shared/pipeline-helpers.groovy'
                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'STARTED',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                ''
                            )
                        }
                        
                        dir("${ENVIRONMENTS_PATH}") {
                            sh 'terragrunt run-all apply --terragrunt-non-interactive -auto-approve'
                        }
                        
                        script {
                            // Send Discord notification for apply success
                            def helpers = load 'jenkins/shared/pipeline-helpers.groovy'
                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'SUCCESS',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Infrastructure changes applied successfully'
                            )
                        }
                    }
                }

                stage('Staging - No Changes') {
                    when {
                        expression { env.STAGING_HAS_CHANGES != 'true' }
                    }
                    steps {
                        echo "ℹ️ Staging: Skipping apply - no infrastructure changes detected"
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage: Plan & Apply Production
        //----------------------------------------------------------------------
        stage('Production') {
            environment {
                ENVIRONMENT = 'production'
                ENVIRONMENTS_PATH = 'environments/us-east-1/production'
                // Map production credentials to AWS and Terraform variables
                AWS_ACCESS_KEY_ID = "${AWS_CREDS_PRODUCTION_USR}"
                AWS_SECRET_ACCESS_KEY = "${AWS_CREDS_PRODUCTION_PSW}"
                TF_VAR_db_username = "${TF_VAR_db_username_production}"
                TF_VAR_db_password = "${TF_VAR_db_password_production}"
                TF_VAR_splunk_admin_password = "${TF_VAR_splunk_admin_password_production}"
                TF_VAR_app_secret_key = "${TF_VAR_app_secret_key_production}"
                TF_VAR_splunk_hec_token = "${TF_VAR_splunk_hec_token_production}"
                TF_VAR_docker_image = "${TF_VAR_docker_image_production}"
                DISCORD_WEBHOOK = "${DISCORD_WEBHOOK_PRODUCTION}"
            }
            stages {
                stage('Production - Init') {
                    steps {
                        dir("${ENVIRONMENTS_PATH}") {
                            sh 'terragrunt run-all init --terragrunt-non-interactive'
                        }
                    }
                }

                stage('Production - Plan') {
                    steps {
                        dir("${ENVIRONMENTS_PATH}") {
                            script {
                                // Run plan and capture output to detect changes
                                def planOutput = sh(
                                    script: 'terragrunt run-all plan --terragrunt-non-interactive -detailed-exitcode -out=tfplan 2>&1 || true',
                                    returnStdout: true
                                ).trim()
                                
                                echo planOutput
                                
                                // Check if there are changes to apply
                                env.PRODUCTION_HAS_CHANGES = planOutput.contains('Plan:') && 
                                    (planOutput.contains('to add') || 
                                     planOutput.contains('to change') || 
                                     planOutput.contains('to destroy'))
                                
                                if (env.PRODUCTION_HAS_CHANGES == 'true') {
                                    echo "✅ Production: Infrastructure changes detected"
                                } else {
                                    echo "ℹ️ Production: No infrastructure changes detected"
                                }
                            }
                        }
                    }
                }

                stage('Production - Approval') {
                    when {
                        expression { env.PRODUCTION_HAS_CHANGES == 'true' }
                    }
                    steps {
                        script {
                            // Send Discord notification requesting approval
                            def helpers = load 'jenkins/shared/pipeline-helpers.groovy'
                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'APPROVAL_REQUIRED',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Production infrastructure changes detected - awaiting approval'
                            )
                            
                            timeout(time: 60, unit: 'MINUTES') {
                                input message: '⚠️ Production infrastructure changes detected. Review the plan and approve.',
                                      ok: 'Apply to Production'
                            }
                        }
                    }
                }

                stage('Production - Apply') {
                    when {
                        expression { env.PRODUCTION_HAS_CHANGES == 'true' }
                    }
                    steps {
                        script {
                            // Send Discord notification for apply start
                            def helpers = load 'jenkins/shared/pipeline-helpers.groovy'
                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'STARTED',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Applying production infrastructure changes'
                            )
                        }
                        
                        dir("${ENVIRONMENTS_PATH}") {
                            sh 'terragrunt run-all apply --terragrunt-non-interactive -auto-approve'
                        }
                        
                        script {
                            // Send Discord notification for apply success
                            def helpers = load 'jenkins/shared/pipeline-helpers.groovy'
                            helpers.sendDiscordNotification(
                                DISCORD_WEBHOOK,
                                'SUCCESS',
                                ENVIRONMENT,
                                'apply',
                                'all',
                                env.BUILD_URL,
                                env.BUILD_NUMBER,
                                'Production infrastructure changes applied successfully'
                            )
                        }
                    }
                }

                stage('Production - No Changes') {
                    when {
                        expression { env.PRODUCTION_HAS_CHANGES != 'true' }
                    }
                    steps {
                        echo "ℹ️ Production: Skipping apply - no infrastructure changes detected"
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage: Summary
        //----------------------------------------------------------------------
        stage('Summary') {
            steps {
                script {
                    echo "======================================"
                    echo "           Pipeline Summary           "
                    echo "======================================"
                    echo "Staging changes detected:    ${env.STAGING_HAS_CHANGES ?: 'false'}"
                    echo "Production changes detected: ${env.PRODUCTION_HAS_CHANGES ?: 'false'}"
                    echo "======================================"
                }
            }
        }
    }

    post {
        failure {
            script {
                echo "❌ Pipeline FAILED"
                
                def errorMessage = currentBuild.rawBuild?.getLog(100)?.join('\n') ?: 'Error details not available'
                def failedEnvironment = env.PRODUCTION_HAS_CHANGES == 'true' ? 'production' : 'staging'
                def discordWebhook = failedEnvironment == 'production' ? DISCORD_WEBHOOK_PRODUCTION : DISCORD_WEBHOOK_STAGING
                
                // Send Discord notification
                def helpers = load 'jenkins/shared/pipeline-helpers.groovy'
                helpers.sendDiscordNotification(
                    discordWebhook,
                    'FAILURE',
                    failedEnvironment,
                    'apply',
                    'all',
                    env.BUILD_URL,
                    env.BUILD_NUMBER,
                    'A Jira ticket has been created for this failure'
                )
                
                // Create Jira ticket for the failure
                try {
                    def ticketKey = helpers.createJiraTicket(
                        JIRA_URL,
                        JIRA_CREDS_USR,
                        JIRA_CREDS_PSW,
                        JIRA_PROJECT_KEY,
                        failedEnvironment,
                        'apply',
                        'all',
                        env.BUILD_URL,
                        errorMessage.take(1000)
                    )
                    echo "Created Jira ticket: ${ticketKey}"
                } catch (Exception e) {
                    echo "Failed to create Jira ticket: ${e.message}"
                }
            }
        }

        success {
            script {
                echo "✅ Pipeline completed successfully"
                
                // Only send summary notification if there were changes applied
                if (env.STAGING_HAS_CHANGES == 'true' || env.PRODUCTION_HAS_CHANGES == 'true') {
                    def changesApplied = []
                    if (env.STAGING_HAS_CHANGES == 'true') changesApplied.add('Staging')
                    if (env.PRODUCTION_HAS_CHANGES == 'true') changesApplied.add('Production')
                    
                    echo "Infrastructure changes applied to: ${changesApplied.join(', ')}"
                } else {
                    echo "No infrastructure changes were applied - all environments up to date"
                }
            }
        }

        always {
            // Clean up workspace
            cleanWs(
                cleanWhenSuccess: true,
                cleanWhenFailure: false,
                deleteDirs: true
            )
        }
    }
}
