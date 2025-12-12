package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestRdsModuleVariablesValidation validates that the RDS module has required variables
func TestRdsModuleVariablesValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/rds",

		Vars: map[string]interface{}{
			"project_name":              "test-project",
			"environment":               "test",
			"vpc_id":                    "vpc-12345678",
			"private_subnet_ids":        []string{"subnet-priv1", "subnet-priv2"},
			"allowed_security_groups":   []string{"sg-12345678"},
			"db_engine":                 "postgres",
			"db_engine_version":         "15.4",
			"db_instance_class":         "db.t3.micro",
			"db_parameter_group_family": "postgres15",
			"db_parameters":             []map[string]interface{}{},
			"db_allocated_storage":      20,
			"db_max_allocated_storage":  100,
			"db_name":                   "testdb",
			"db_username":               "admin",
			"db_password":               "SecurePassword123!",
			"db_port":                   5432,
			"multi_az":                  false,
			"deletion_protection":       false,
			"skip_final_snapshot":       true,
			"backup_retention_period":   7,
			"enable_enhanced_monitoring": false,
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

// TestRdsModuleDatabaseEngines tests various database engine configurations
func TestRdsModuleDatabaseEngines(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name                   string
		dbEngine               string
		dbEngineVersion        string
		dbParameterGroupFamily string
	}{
		{
			name:                   "PostgreSQL15",
			dbEngine:               "postgres",
			dbEngineVersion:        "15.4",
			dbParameterGroupFamily: "postgres15",
		},
		{
			name:                   "PostgreSQL14",
			dbEngine:               "postgres",
			dbEngineVersion:        "14.9",
			dbParameterGroupFamily: "postgres14",
		},
		{
			name:                   "MySQL8",
			dbEngine:               "mysql",
			dbEngineVersion:        "8.0.35",
			dbParameterGroupFamily: "mysql8.0",
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/rds",
				Vars: map[string]interface{}{
					"project_name":              "test-project",
					"environment":               "test",
					"vpc_id":                    "vpc-12345678",
					"private_subnet_ids":        []string{"subnet-priv1", "subnet-priv2"},
					"allowed_security_groups":   []string{"sg-12345678"},
					"db_engine":                 tc.dbEngine,
					"db_engine_version":         tc.dbEngineVersion,
					"db_instance_class":         "db.t3.micro",
					"db_parameter_group_family": tc.dbParameterGroupFamily,
					"db_parameters":             []map[string]interface{}{},
					"db_allocated_storage":      20,
					"db_max_allocated_storage":  100,
					"db_name":                   "testdb",
					"db_username":               "admin",
					"db_password":               "SecurePassword123!",
					"db_port":                   5432,
					"multi_az":                  false,
					"deletion_protection":       false,
					"skip_final_snapshot":       true,
					"backup_retention_period":   7,
					"enable_enhanced_monitoring": false,
					"tags":                      map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestRdsModuleInstanceClasses tests various RDS instance class configurations
func TestRdsModuleInstanceClasses(t *testing.T) {
	t.Parallel()

	instanceClasses := []string{
		"db.t3.micro",
		"db.t3.small",
		"db.t3.medium",
		"db.r5.large",
		"db.r5.xlarge",
	}

	for _, instanceClass := range instanceClasses {
		instanceClass := instanceClass
		t.Run(instanceClass, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/rds",
				Vars: map[string]interface{}{
					"project_name":              "test-project",
					"environment":               "test",
					"vpc_id":                    "vpc-12345678",
					"private_subnet_ids":        []string{"subnet-priv1", "subnet-priv2"},
					"allowed_security_groups":   []string{"sg-12345678"},
					"db_engine":                 "postgres",
					"db_engine_version":         "15.4",
					"db_instance_class":         instanceClass,
					"db_parameter_group_family": "postgres15",
					"db_parameters":             []map[string]interface{}{},
					"db_allocated_storage":      20,
					"db_max_allocated_storage":  100,
					"db_name":                   "testdb",
					"db_username":               "admin",
					"db_password":               "SecurePassword123!",
					"db_port":                   5432,
					"multi_az":                  false,
					"deletion_protection":       false,
					"skip_final_snapshot":       true,
					"backup_retention_period":   7,
					"enable_enhanced_monitoring": false,
					"tags":                      map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestRdsModuleProductionConfiguration tests production-grade configuration
func TestRdsModuleProductionConfiguration(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/rds",
		Vars: map[string]interface{}{
			"project_name":              "production-app",
			"environment":               "production",
			"vpc_id":                    "vpc-12345678",
			"private_subnet_ids":        []string{"subnet-priv1", "subnet-priv2", "subnet-priv3"},
			"allowed_security_groups":   []string{"sg-12345678", "sg-87654321"},
			"db_engine":                 "postgres",
			"db_engine_version":         "15.4",
			"db_instance_class":         "db.r5.large",
			"db_parameter_group_family": "postgres15",
			"db_parameters":             []map[string]interface{}{},
			"db_allocated_storage":      100,
			"db_max_allocated_storage":  500,
			"db_name":                   "productiondb",
			"db_username":               "admin",
			"db_password":               "VerySecureProductionPassword123!",
			"db_port":                   5432,
			"multi_az":                  true,
			"deletion_protection":       true,
			"skip_final_snapshot":       false,
			"backup_retention_period":   30,
			"enable_enhanced_monitoring": true,
			"tags": map[string]string{
				"Environment": "production",
				"Critical":    "true",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	result := terraform.Validate(t, terraformOptions)
	assert.NotNil(t, result)
}

// TestRdsModuleStorageConfiguration tests storage configurations
func TestRdsModuleStorageConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name               string
		allocatedStorage   int
		maxAllocatedStorage int
	}{
		{
			name:               "SmallStorage",
			allocatedStorage:   20,
			maxAllocatedStorage: 50,
		},
		{
			name:               "MediumStorage",
			allocatedStorage:   100,
			maxAllocatedStorage: 500,
		},
		{
			name:               "LargeStorage",
			allocatedStorage:   500,
			maxAllocatedStorage: 1000,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/rds",
				Vars: map[string]interface{}{
					"project_name":              "test-project",
					"environment":               "test",
					"vpc_id":                    "vpc-12345678",
					"private_subnet_ids":        []string{"subnet-priv1", "subnet-priv2"},
					"allowed_security_groups":   []string{"sg-12345678"},
					"db_engine":                 "postgres",
					"db_engine_version":         "15.4",
					"db_instance_class":         "db.t3.micro",
					"db_parameter_group_family": "postgres15",
					"db_parameters":             []map[string]interface{}{},
					"db_allocated_storage":      tc.allocatedStorage,
					"db_max_allocated_storage":  tc.maxAllocatedStorage,
					"db_name":                   "testdb",
					"db_username":               "admin",
					"db_password":               "SecurePassword123!",
					"db_port":                   5432,
					"multi_az":                  false,
					"deletion_protection":       false,
					"skip_final_snapshot":       true,
					"backup_retention_period":   7,
					"enable_enhanced_monitoring": false,
					"tags":                      map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}
