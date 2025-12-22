//------------------------------------------------------------------------------
// Shared Jenkins Library Functions
// Common functions used by staging and production pipelines
//------------------------------------------------------------------------------

//==============================================================================
// Terragrunt Execution Functions (Direct Execution with TFC State Backend)
//==============================================================================

/**
 * Run terragrunt plan across all modules in dependency order
 * @param envPath Path to environment directory (e.g., 'environments/us-east-1/staging')
 * @param moduleOrder Comma-separated list of modules in dependency order
 * @return true if any module has changes, false otherwise
 */
def runTerragruntPlan(envPath, moduleOrder) {
    def modules = moduleOrder.split(',')
    def hasAnyChanges = false

    echo "📋 Running terragrunt plan for ${modules.size()} modules..."

    modules.each { module ->
        def modulePath = "${envPath}/${module.trim()}"
        echo "\\n═══════════════════════════════════════════════════"
        echo "  MODULE: ${module.trim()}"
        echo "  PATH: ${modulePath}"
        echo "═══════════════════════════════════════════════════"

        // Initialize terragrunt
        sh """
            cd ${modulePath}
            terragrunt init -upgrade
        """

        // Run plan and check exit code
        // Exit code 0 = no changes, 2 = changes detected, 1 = error
        def exitCode = sh(
            script: """
                cd ${modulePath}
                terragrunt plan -detailed-exitcode -out=tfplan
            """,
            returnStatus: true
        )

        if (exitCode == 2) {
            echo "✅ [${module}] Changes detected"
            hasAnyChanges = true
        } else if (exitCode == 0) {
            echo "ℹ️ [${module}] No changes"
        } else {
            error("❌ [${module}] Plan failed with exit code ${exitCode}")
        }
    }

    echo "\\n════════════════════════════════════════"
    if (hasAnyChanges) {
        echo "  ✅ CHANGES DETECTED - Apply required  "
    } else {
        echo "  ℹ️ NO CHANGES - Infrastructure up-to-date"
    }
    echo "════════════════════════════════════════\\n"

    return hasAnyChanges
}

/**
 * Run terragrunt apply across all modules in dependency order
 * @param envPath Path to environment directory
 * @param moduleOrder Comma-separated list of modules in dependency order
 */
def runTerragruntApply(envPath, moduleOrder) {
    def modules = moduleOrder.split(',')

    echo "🚀 Running terragrunt apply for ${modules.size()} modules..."

    modules.each { module ->
        def modulePath = "${envPath}/${module.trim()}"
        echo "\\n═══════════════════════════════════════════════════"
        echo "  APPLYING: ${module.trim()}"
        echo "  PATH: ${modulePath}"
        echo "═══════════════════════════════════════════════════"

        // Apply using saved plan file
        sh """
            cd ${modulePath}
            terragrunt apply -auto-approve tfplan
        """

        echo "✅ [${module}] Apply completed successfully"
    }

    echo "\\n════════════════════════════════════════"
    echo "  ✅ ALL MODULES APPLIED SUCCESSFULLY    "
    echo "════════════════════════════════════════\\n"
}

//==============================================================================
// Terraform Cloud API Functions (Deprecated - Only for reference)
//==============================================================================

/**
 * Get list of workspaces matching a prefix from Terraform Cloud
 * @deprecated Use direct terragrunt execution instead
 * @param tfcApiUrl Terraform Cloud API URL
 * @param tfcToken Terraform Cloud API token
 * @param tfcOrganization Terraform Cloud organization name
 * @param prefix Workspace name prefix to filter by
 * @return List of workspace names
 */
def getTerraformCloudWorkspaces(tfcApiUrl, tfcToken, tfcOrganization, prefix) {
    echo "📋 Fetching workspaces with prefix: ${prefix}"

    def response = sh(
        script: """
            curl -s -H "Authorization: Bearer ${tfcToken}" \\
                 -H "Content-Type: application/vnd.api+json" \\
                 "${tfcApiUrl}/organizations/${tfcOrganization}/workspaces" | \\
            jq -r '.data[] | select(.attributes.name | startswith("${prefix}")) | .attributes.name'
        """,
        returnStdout: true
    ).trim()

    def workspaces = response.split('\n').findAll { it }
    echo "Found ${workspaces.size()} workspaces: ${workspaces.join(', ')}"
    return workspaces
}

/**
 * Trigger a Terraform Cloud run (plan or apply)
 * @deprecated Use direct terragrunt execution instead
 * @param tfcApiUrl Terraform Cloud API URL
 * @param tfcToken Terraform Cloud API token
 * @param tfcOrganization Terraform Cloud organization name
 * @param workspace Workspace name
 * @param operation Operation type ('plan' or 'apply')
 * @param buildNumber Jenkins build number
 * @return Run ID
 */
def triggerTerraformCloudRun(tfcApiUrl, tfcToken, tfcOrganization, workspace, operation, buildNumber) {
    echo "🚀 Triggering ${operation} for workspace: ${workspace}"

    def message = "Triggered by Jenkins - Build #${buildNumber}"
    def isDestroy = false
    def autoApply = (operation == 'apply')

    // Get workspace ID first
    def workspaceId = sh(
        script: """
            curl -s -H "Authorization: Bearer ${tfcToken}" \\
                "${tfcApiUrl}/organizations/${tfcOrganization}/workspaces/${workspace}" | \\
                jq -r '.data.id'
        """,
        returnStdout: true
    ).trim()

    // Create run via API
    def runId = sh(
        script: """
            curl -s -X POST \\
                -H "Authorization: Bearer ${tfcToken}" \\
                -H "Content-Type: application/vnd.api+json" \\
                -d '{
                    "data": {
                        "type": "runs",
                        "attributes": {
                            "message": "${message}",
                            "is-destroy": ${isDestroy},
                            "auto-apply": ${autoApply}
                        },
                        "relationships": {
                            "workspace": {
                                "data": {
                                    "type": "workspaces",
                                    "id": "${workspaceId}"
                                }
                            }
                        }
                    }
                }' \\
                "${tfcApiUrl}/runs" | jq -r '.data.id'
        """,
        returnStdout: true
    ).trim()

    echo "✅ Run triggered: ${runId} for workspace: ${workspace}"
    echo "🔗 View in UI: https://app.terraform.io/app/${tfcOrganization}/workspaces/${workspace}/runs/${runId}"

    return runId
}

/**
 * Monitor Terraform Cloud runs until completion
 * @param tfcApiUrl Terraform Cloud API URL
 * @param tfcToken Terraform Cloud API token
 * @param runIds Map of workspace names to run IDs
 * @param environment Environment name (for logging)
 * @param isApply Whether this is an apply operation (vs plan)
 * @return true if any run has changes, false otherwise
 */
def monitorTerraformCloudRuns(tfcApiUrl, tfcToken, runIds, environment, isApply = false) {
    echo "👀 Monitoring ${runIds.size()} Terraform Cloud runs for ${environment}..."

    def hasChanges = false
    def maxWaitMinutes = 60
    def checkIntervalSeconds = 15
    def maxChecks = (maxWaitMinutes * 60) / checkIntervalSeconds

    runIds.each { workspace, runId ->
        echo "Monitoring run ${runId} for workspace: ${workspace}"

        def completed = false
        def checks = 0

        while (!completed && checks < maxChecks) {
            def status = sh(
                script: """
                    curl -s -H "Authorization: Bearer ${tfcToken}" \\
                        "${tfcApiUrl}/runs/${runId}" | \\
                    jq -r '.data.attributes.status'
                """,
                returnStdout: true
            ).trim()

            echo "[${workspace}] Run status: ${status} (check ${checks + 1}/${maxChecks})"

            // Check for completion statuses
            if (status in ['planned', 'applied', 'planned_and_finished']) {
                completed = true

                if (!isApply) {
                    // For plan operations, check if there are changes
                    def hasChangesInRun = sh(
                        script: """
                            curl -s -H "Authorization: Bearer ${tfcToken}" \\
                                "${tfcApiUrl}/runs/${runId}" | \\
                            jq -r '.data.attributes["has-changes"]'
                        """,
                        returnStdout: true
                    ).trim()

                    if (hasChangesInRun == 'true') {
                        hasChanges = true
                        echo "✅ [${workspace}] Changes detected in run"
                    } else {
                        echo "ℹ️ [${workspace}] No changes in run"
                    }
                } else {
                    echo "✅ [${workspace}] Apply completed successfully"
                }
            } else if (status in ['errored', 'canceled', 'discarded']) {
                error("❌ [${workspace}] Run ${runId} ${status}")
            } else if (status == 'policy_checked' || status == 'policy_override') {
                // Waiting for apply confirmation
                echo "⏸️ [${workspace}] Run is waiting for confirmation"
                completed = true
                hasChanges = true
            } else if (status in ['applying', 'planning', 'pending', 'queued']) {
                // Still in progress
                echo "⏳ [${workspace}] Run in progress: ${status}"
            }

            if (!completed) {
                sleep(checkIntervalSeconds)
                checks++
            }
        }

        if (!completed) {
            error("❌ [${workspace}] Timeout waiting for run ${runId} to complete after ${maxWaitMinutes} minutes")
        }
    }

    return hasChanges
}

/**
 * Confirm/Apply a Terraform Cloud run
 * @param tfcApiUrl Terraform Cloud API URL
 * @param tfcToken Terraform Cloud API token
 * @param runId Run ID to confirm
 * @param workspace Workspace name (for logging)
 * @param buildNumber Jenkins build number
 */
def confirmTerraformCloudRun(tfcApiUrl, tfcToken, runId, workspace, buildNumber) {
    echo "✅ Confirming run ${runId} for workspace: ${workspace}"

    sh """
        curl -s -X POST \\
            -H "Authorization: Bearer ${tfcToken}" \\
            -H "Content-Type: application/vnd.api+json" \\
            -d '{"comment": "Approved by Jenkins Build #${buildNumber}"}' \\
            "${tfcApiUrl}/runs/${runId}/actions/apply"
    """

    echo "✅ Apply confirmed for run: ${runId}"
}

//==============================================================================
// Legacy Tool Setup (deprecated - not needed for Terraform Cloud)
//==============================================================================

/**
 * Setup Terraform and Terragrunt tools with version verification and checksum validation
 * @deprecated Not needed when using Terraform Cloud API
 */
def setupTools(terraformVersion, terragruntVersion) {
    // Check if sudo is available
    def hasSudo = sh(script: 'command -v sudo', returnStatus: true) == 0
    def sudoCmd = hasSudo ? 'sudo' : ''

    if (!hasSudo) {
        echo "Warning: sudo not available. Tools will be installed in current directory or may fail if /usr/local/bin is not writable."
    }

    // Install Terraform with checksum verification
    sh """
        CURRENT_VERSION=\$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || echo 'none')
        if [ "\${CURRENT_VERSION}" != "${terraformVersion}" ]; then
            echo "Installing Terraform ${terraformVersion}..."

            # Download Terraform
            wget -q https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_linux_amd64.zip

            # Download and verify checksum
            wget -q https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_SHA256SUMS
            wget -q https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_SHA256SUMS.sig

            # Verify checksum
            grep "terraform_${terraformVersion}_linux_amd64.zip" terraform_${terraformVersion}_SHA256SUMS | sha256sum -c -
            if [ \$? -ne 0 ]; then
                echo "ERROR: Terraform checksum verification failed!"
                rm -f terraform_${terraformVersion}_linux_amd64.zip terraform_${terraformVersion}_SHA256SUMS*
                exit 1
            fi

            # Extract and install
            unzip -o terraform_${terraformVersion}_linux_amd64.zip
            ${sudoCmd} mv terraform /usr/local/bin/ || mv terraform \${HOME}/.local/bin/ || echo "Warning: Could not move terraform binary"
            rm -f terraform_${terraformVersion}_linux_amd64.zip terraform_${terraformVersion}_SHA256SUMS*
        else
            echo "Terraform ${terraformVersion} already installed"
        fi
        terraform version
    """

    // Install Terragrunt with version verification
    sh """
        CURRENT_VERSION=\$(terragrunt --version 2>/dev/null | head -n 1 | awk '{print \$3}' | sed 's/v//' || echo 'none')
        if [ "\${CURRENT_VERSION}" != "${terragruntVersion}" ]; then
            echo "Installing Terragrunt ${terragruntVersion}..."

            # Download Terragrunt
            wget -q https://github.com/gruntwork-io/terragrunt/releases/download/v${terragruntVersion}/terragrunt_linux_amd64

            # Download and verify checksum
            wget -q https://github.com/gruntwork-io/terragrunt/releases/download/v${terragruntVersion}/SHA256SUMS

            # Verify checksum
            grep "terragrunt_linux_amd64" SHA256SUMS | sha256sum -c -
            if [ \$? -ne 0 ]; then
                echo "ERROR: Terragrunt checksum verification failed!"
                rm -f terragrunt_linux_amd64 SHA256SUMS
                exit 1
            fi

            chmod +x terragrunt_linux_amd64
            ${sudoCmd} mv terragrunt_linux_amd64 /usr/local/bin/terragrunt || mv terragrunt_linux_amd64 \${HOME}/.local/bin/terragrunt || echo "Warning: Could not move terragrunt binary"
            rm -f SHA256SUMS
        else
            echo "Terragrunt ${terragruntVersion} already installed"
        fi
        terragrunt --version
    """
}

//==============================================================================
// Discord Notification Functions
//==============================================================================

def sendDiscordNotification(webhookUrl, status, environment, action, targetModule, buildUrl, buildNumber, additionalMessage = '') {
    def color
    def emoji
    def title

    switch(status) {
        case 'SUCCESS':
            color = 3066993  // Green
            emoji = '✅'
            title = "Infrastructure ${action.toUpperCase()} Successful"
            break
        case 'FAILURE':
            color = 15158332  // Red
            emoji = '❌'
            title = "Infrastructure ${action.toUpperCase()} Failed"
            break
        case 'STARTED':
            color = 3447003  // Blue
            emoji = '🚀'
            title = "Infrastructure ${action.toUpperCase()} Started"
            break
        case 'APPROVAL_REQUIRED':
            color = 16776960  // Yellow
            emoji = '⏳'
            title = "Approval Required"
            break
        default:
            color = 9807270  // Gray
            emoji = 'ℹ️'
            title = "Infrastructure Update"
    }

    // Build proper JSON structure to prevent injection and malformed JSON
    def fields = [
        [name: 'Environment', value: environment, inline: true],
        [name: 'Action', value: action, inline: true],
        [name: 'Module', value: targetModule, inline: true],
        [name: 'Build', value: "[#${buildNumber}](${buildUrl})", inline: true]
    ]

    // Add additional message field if provided
    if (additionalMessage) {
        fields.add([name: 'Details', value: additionalMessage, inline: false])
    }

    def payloadMap = [
        embeds: [[
            title: "${emoji} ${title}",
            color: color,
            fields: fields,
            footer: [text: 'Gogs Infrastructure AWS'],
            timestamp: new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))
        ]]
    ]

    // Convert to JSON and write to temp file to prevent shell injection
    def payload = groovy.json.JsonOutput.toJson(payloadMap)
    def tempFile = "discord_payload_${UUID.randomUUID().toString()}.json"
    writeFile file: tempFile, text: payload

    try {
        // Send notification with error checking
        def result = sh(
            script: """
                HTTP_CODE=\$(curl -s -w "%{http_code}" -o /tmp/discord_response.txt \
                    -X POST -H "Content-Type: application/json" \
                    -d @${tempFile} \
                    "${webhookUrl}")
                echo \$HTTP_CODE
            """,
            returnStdout: true
        ).trim()

        def responseBody = ''
        try {
            responseBody = readFile('/tmp/discord_response.txt').trim()
        } catch (Exception e) {
            echo "Could not read Discord response file: ${e.message}"
        }

        if (result == '200' || result == '204') {
            echo "✅ Discord notification sent successfully (HTTP ${result})"
        } else {
            echo "⚠️ Discord notification returned HTTP ${result}"
            if (responseBody) {
                echo "Response: ${responseBody}"
            }
        }
    } catch (Exception e) {
        echo "❌ Failed to send Discord notification: ${e.message}"
    } finally {
        // Cleanup temp files
        sh "rm -f ${tempFile} /tmp/discord_response.txt"
    }
}

//==============================================================================
// Jira Integration Functions
//==============================================================================

def createJiraTicket(jiraUrl, jiraUser, jiraToken, projectKey, environment, action, targetModule, buildUrl, errorMessage) {
    def summary = "Infrastructure ${action} Failed - ${environment.toUpperCase()}"

    // Escape special characters in error message for Jira wiki markup
    def safeErrorMessage = errorMessage.replaceAll('\\\\', '\\\\\\\\').replaceAll(/\{/, '\\\\{').replaceAll(/\}/, '\\\\}')

    def description = """
h2. Infrastructure Pipeline Failure

*Environment:* ${environment}
*Action:* ${action}
*Module:* ${targetModule}
*Build URL:* ${buildUrl}

h3. Error Details
{code}
${safeErrorMessage}
{code}

h3. Next Steps
# Review the Jenkins build logs
# Identify the root cause
# Fix the issue and re-run the pipeline
    """

    // Build JSON payload safely
    def payloadMap = [
        fields: [
            project: [key: projectKey],
            summary: summary,
            description: description,
            issuetype: [name: 'Bug'],
            priority: [name: environment == 'production' ? 'Critical' : 'High'],
            labels: ['infrastructure', 'terraform', environment, 'auto-created']
        ]
    ]

    def payload = groovy.json.JsonOutput.toJson(payloadMap)

    // Write payload to temp file to prevent shell injection
    def tempPayloadFile = "jira_payload_${UUID.randomUUID().toString()}.json"
    def tempNetrcFile = ".netrc_${UUID.randomUUID().toString()}"

    writeFile file: tempPayloadFile, text: payload

    try {
        // Extract hostname from Jira URL for netrc
        def jiraHost = sh(
            script: "echo '${jiraUrl}' | awk -F/ '{print \$3}'",
            returnStdout: true
        ).trim()

        // Create secure netrc file for credentials
        sh """
            cat > ${tempNetrcFile} << EOF
machine ${jiraHost}
login ${jiraUser}
password ${jiraToken}
EOF
            chmod 600 ${tempNetrcFile}
        """

        // Make API call with error checking
        def response = sh(
            script: """
                HTTP_CODE=\$(curl -s -w "%{http_code}" -o /tmp/jira_response.json \
                    -X POST \
                    -H "Content-Type: application/json" \
                    --netrc-file ${tempNetrcFile} \
                    -d @${tempPayloadFile} \
                    "${jiraUrl}/rest/api/2/issue")

                cat /tmp/jira_response.json
                echo ""
                echo "HTTP_CODE:\$HTTP_CODE"
            """,
            returnStdout: true
        ).trim()

        // Extract HTTP code from response
        def lines = response.split('\n')
        def httpCode = lines[-1].replace('HTTP_CODE:', '')
        def responseBody = lines[0..-2].join('\n')

        if (httpCode.startsWith('20')) {
            // Success - parse ticket key
            def ticketKey
            try {
                ticketKey = readJSON(text: responseBody).key
                echo "✅ Created Jira ticket: ${ticketKey}"
                echo "🔗 View at: ${jiraUrl}/browse/${ticketKey}"
                return ticketKey
            } catch (Exception e) {
                echo "⚠️ Jira ticket created but failed to parse response. Raw response: ${responseBody}"
                echo "Parse error: ${e.message}"
                return null
            }
        } else {
            echo "❌ Failed to create Jira ticket. HTTP ${httpCode}"
            echo "Response: ${responseBody}"
            error("Jira API returned HTTP ${httpCode}")
        }
    } catch (Exception e) {
        echo "❌ Failed to create Jira ticket: ${e.message}"
        throw e
    } finally {
        // Cleanup temp files securely
        sh """
            rm -f ${tempPayloadFile}
            rm -f ${tempNetrcFile}
            rm -f /tmp/jira_response.json
        """
    }
}

return this
