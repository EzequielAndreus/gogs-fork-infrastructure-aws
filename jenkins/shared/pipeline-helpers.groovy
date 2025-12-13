//------------------------------------------------------------------------------
// Shared Jenkins Library Functions
// Common functions used by staging and production pipelines
//------------------------------------------------------------------------------

def setupTools(terraformVersion, terragruntVersion) {
    // Install Terraform
    sh """
        if ! command -v terraform &> /dev/null || [ "\$(terraform version -json | jq -r '.terraform_version')" != "${terraformVersion}" ]; then
            echo "Installing Terraform ${terraformVersion}..."
            wget -q https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_linux_amd64.zip
            unzip -o terraform_${terraformVersion}_linux_amd64.zip
            sudo mv terraform /usr/local/bin/
            rm terraform_${terraformVersion}_linux_amd64.zip
        fi
        terraform version
    """

    // Install Terragrunt
    sh """
        if ! command -v terragrunt &> /dev/null; then
            echo "Installing Terragrunt ${terragruntVersion}..."
            wget -q https://github.com/gruntwork-io/terragrunt/releases/download/v${terragruntVersion}/terragrunt_linux_amd64
            chmod +x terragrunt_linux_amd64
            sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
        fi
        terragrunt --version
    """
}

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
    
    def payload = """
    {
        "embeds": [{
            "title": "${emoji} ${title}",
            "color": ${color},
            "fields": [
                {
                    "name": "Environment",
                    "value": "${environment}",
                    "inline": true
                },
                {
                    "name": "Action",
                    "value": "${action}",
                    "inline": true
                },
                {
                    "name": "Module",
                    "value": "${targetModule}",
                    "inline": true
                },
                {
                    "name": "Build",
                    "value": "[#${buildNumber}](${buildUrl})",
                    "inline": true
                }
            ],
            "footer": {
                "text": "Gogs Infrastructure AWS"
            },
            "timestamp": "${new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))}"
        }]
    }
    """
    
    if (additionalMessage) {
        payload = payload.replace('"footer"', """
            {
                "name": "Details",
                "value": "${additionalMessage}",
                "inline": false
            }
        ],
        "footer""")
    }
    
    sh """
        curl -X POST -H "Content-Type: application/json" \
            -d '${payload}' \
            "${webhookUrl}"
    """
}

def createJiraTicket(jiraUrl, jiraUser, jiraToken, projectKey, environment, action, targetModule, buildUrl, errorMessage) {
    def summary = "Infrastructure ${action} Failed - ${environment.toUpperCase()}"
    def description = """
h2. Infrastructure Pipeline Failure

*Environment:* ${environment}
*Action:* ${action}
*Module:* ${targetModule}
*Build URL:* ${buildUrl}

h3. Error Details
{code}
${errorMessage}
{code}

h3. Next Steps
# Review the Jenkins build logs
# Identify the root cause
# Fix the issue and re-run the pipeline
    """
    
    def payload = """
    {
        "fields": {
            "project": {
                "key": "${projectKey}"
            },
            "summary": "${summary}",
            "description": "${description}",
            "issuetype": {
                "name": "Bug"
            },
            "priority": {
                "name": "${environment == 'production' ? 'Critical' : 'High'}"
            },
            "labels": ["infrastructure", "terraform", "${environment}", "auto-created"]
        }
    }
    """
    
    def response = sh(
        script: """
            curl -s -X POST \
                -H "Content-Type: application/json" \
                -u "${jiraUser}:${jiraToken}" \
                -d '${payload}' \
                "${jiraUrl}/rest/api/2/issue"
        """,
        returnStdout: true
    ).trim()
    
    def ticketKey = readJSON(text: response).key
    echo "Created Jira ticket: ${ticketKey}"
    return ticketKey
}

return this
