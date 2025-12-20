package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestSecretsManagerModuleVariablesValidation validates that the Secrets Manager module has required variables
func TestSecretsManagerModuleVariablesValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/secrets-manager",

		Vars: map[string]interface{}{
			"project_name":            "test-project",
			"environment":             "test",
			"kms_key_id":              nil,
			"create_kms_key":          true,
			"recovery_window_in_days": 7,
			"db_username":             "admin",
			"db_password":             "SecurePassword123!",
			"db_host":                 "db.example.com",
			"db_port":                 5432,
			"db_name":                 "testdb",
			"application_secrets": map[string]string{
				"API_KEY":     "test-api-key",
				"SECRET_KEY":  "test-secret-key",
			},
			"create_splunk_secret":    true,
			"splunk_admin_password":   "SplunkAdmin123!",
			"splunk_hec_token":        "12345678-1234-1234-1234-123456789012",
			"create_dockerhub_secret": true,
			"dockerhub_username":      "testuser",
			"dockerhub_password":      "testpassword",
			"tags": map[string]string{
				"Environment": "test",
			},
		},

		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	result := terraform.Validate(t, terraformOptions)
	assert.NotNil(t, result)
}

// TestSecretsManagerModuleSecretTypes tests various secret type configurations
func TestSecretsManagerModuleSecretTypes(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name                 string
		createSplunkSecret   bool
		createDockerhubSecret bool
	}{
		{
			name:                 "AllSecrets",
			createSplunkSecret:   true,
			createDockerhubSecret: true,
		},
		{
			name:                 "OnlyDatabaseAndApp",
			createSplunkSecret:   false,
			createDockerhubSecret: false,
		},
		{
			name:                 "WithSplunk",
			createSplunkSecret:   true,
			createDockerhubSecret: false,
		},
		{
			name:                 "WithDockerhub",
			createSplunkSecret:   false,
			createDockerhubSecret: true,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/secrets-manager",
				Vars: map[string]interface{}{
					"project_name":            "test-project",
					"environment":             "test",
					"kms_key_id":              nil,
					"create_kms_key":          true,
					"recovery_window_in_days": 7,
					"db_username":             "admin",
					"db_password":             "SecurePassword123!",
					"db_host":                 "db.example.com",
					"db_port":                 5432,
					"db_name":                 "testdb",
					"application_secrets":     map[string]string{},
					"create_splunk_secret":    tc.createSplunkSecret,
					"splunk_admin_password":   "SplunkAdmin123!",
					"splunk_hec_token":        "12345678-1234-1234-1234-123456789012",
					"create_dockerhub_secret": tc.createDockerhubSecret,
					"dockerhub_username":      "testuser",
					"dockerhub_password":      "testpassword",
					"tags":                    map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestSecretsManagerModuleKMSConfiguration tests KMS key configurations
func TestSecretsManagerModuleKMSConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name         string
		createKMSKey bool
		kmsKeyID     interface{}
	}{
		{
			name:         "CreateNewKMSKey",
			createKMSKey: true,
			kmsKeyID:     nil,
		},
		{
			name:         "UseExistingKMSKey",
			createKMSKey: false,
			kmsKeyID:     "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
		},
		{
			name:         "UseDefaultEncryption",
			createKMSKey: false,
			kmsKeyID:     nil,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/secrets-manager",
				Vars: map[string]interface{}{
					"project_name":            "test-project",
					"environment":             "test",
					"kms_key_id":              tc.kmsKeyID,
					"create_kms_key":          tc.createKMSKey,
					"recovery_window_in_days": 7,
					"db_username":             "admin",
					"db_password":             "SecurePassword123!",
					"db_host":                 "db.example.com",
					"db_port":                 5432,
					"db_name":                 "testdb",
					"application_secrets":     map[string]string{},
					"create_splunk_secret":    false,
					"splunk_admin_password":   "",
					"splunk_hec_token":        "",
					"create_dockerhub_secret": false,
					"dockerhub_username":      "",
					"dockerhub_password":      "",
					"tags":                    map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestSecretsManagerModuleRecoveryWindow tests recovery window configurations
func TestSecretsManagerModuleRecoveryWindow(t *testing.T) {
	t.Parallel()

	recoveryWindows := []int{0, 7, 14, 30}

	for _, window := range recoveryWindows {
		window := window
		t.Run("RecoveryWindow_"+strconv.Itoa(window)), func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/secrets-manager",
				Vars: map[string]interface{}{
					"project_name":            "test-project",
					"environment":             "test",
					"kms_key_id":              nil,
					"create_kms_key":          false,
					"recovery_window_in_days": window,
					"db_username":             "admin",
					"db_password":             "SecurePassword123!",
					"db_host":                 "db.example.com",
					"db_port":                 5432,
					"db_name":                 "testdb",
					"application_secrets":     map[string]string{},
					"create_splunk_secret":    false,
					"splunk_admin_password":   "",
					"splunk_hec_token":        "",
					"create_dockerhub_secret": false,
					"dockerhub_username":      "",
					"dockerhub_password":      "",
					"tags":                    map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestSecretsManagerModuleApplicationSecrets tests various application secret configurations
func TestSecretsManagerModuleApplicationSecrets(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name               string
		applicationSecrets map[string]string
	}{
		{
			name:               "NoAppSecrets",
			applicationSecrets: map[string]string{},
		},
		{
			name: "SingleSecret",
			applicationSecrets: map[string]string{
				"API_KEY": "placeholder-api-key",
			},
		},
		{
			name: "MultipleSecrets",
			applicationSecrets: map[string]string{
				"API_KEY":        "placeholder-api-key",
				"SECRET_KEY":     "placeholder-secret-key",
				"ENCRYPTION_KEY": "placeholder-encryption-key",
				"JWT_SECRET":     "placeholder-jwt-secret",
			},
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/secrets-manager",
				Vars: map[string]interface{}{
					"project_name":            "test-project",
					"environment":             "test",
					"kms_key_id":              nil,
					"create_kms_key":          false,
					"recovery_window_in_days": 7,
					"db_username":             "admin",
					"db_password":             "SecurePassword123!",
					"db_host":                 "db.example.com",
					"db_port":                 5432,
					"db_name":                 "testdb",
					"application_secrets":     tc.applicationSecrets,
					"create_splunk_secret":    false,
					"splunk_admin_password":   "",
					"splunk_hec_token":        "",
					"create_dockerhub_secret": false,
					"dockerhub_username":      "",
					"dockerhub_password":      "",
					"tags":                    map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestSecretsManagerModuleDatabasePorts tests different database port configurations
func TestSecretsManagerModuleDatabasePorts(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name   string
		dbPort int
	}{
		{
			name:   "PostgreSQLDefaultPort",
			dbPort: 5432,
		},
		{
			name:   "MySQLDefaultPort",
			dbPort: 3306,
		},
		{
			name:   "SQLServerDefaultPort",
			dbPort: 1433,
		},
		{
			name:   "CustomPort",
			dbPort: 5433,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/secrets-manager",
				Vars: map[string]interface{}{
					"project_name":            "test-project",
					"environment":             "test",
					"kms_key_id":              nil,
					"create_kms_key":          false,
					"recovery_window_in_days": 7,
					"db_username":             "admin",
					"db_password":             "SecurePassword123!",
					"db_host":                 "db.example.com",
					"db_port":                 tc.dbPort,
					"db_name":                 "testdb",
					"application_secrets":     map[string]string{},
					"create_splunk_secret":    false,
					"splunk_admin_password":   "",
					"splunk_hec_token":        "",
					"create_dockerhub_secret": false,
					"dockerhub_username":      "",
					"dockerhub_password":      "",
					"tags":                    map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}
