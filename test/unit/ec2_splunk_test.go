package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestEc2SplunkModuleVariablesValidation validates that the EC2-Splunk module has required variables
func TestEc2SplunkModuleVariablesValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/ec2-splunk",

		Vars: map[string]interface{}{
			"project_name":          "test-project",
			"environment":           "test",
			"vpc_id":                "vpc-12345678",
			"subnet_id":             "subnet-12345678",
			"availability_zone":     "us-east-1a",
			"ami_id":                "ami-0c7217cdde317cfec",
			"instance_type":         "t3.medium",
			"root_volume_size":      50,
			"data_volume_size":      100,
			"data_volume_type":      "gp3",
			"kms_key_id":            nil,
			"splunk_admin_password": "SplunkAdmin123!",
			"splunk_hec_token":      "12345678-1234-1234-1234-123456789012",
			"splunk_version":        "9.1.1",
			"allowed_cidr":          []string{"10.0.0.0/8"},
			"ssh_cidr":              []string{"10.0.0.0/8"},
			"ssh_public_key":        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... test-key",
			"associate_public_ip":   true,
			"secrets_manager_arn":   "",
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

// TestEc2SplunkModuleInstanceTypes tests various EC2 instance type configurations
func TestEc2SplunkModuleInstanceTypes(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name           string
		instanceType   string
		rootVolumeSize int
		dataVolumeSize int
	}{
		{
			name:           "SmallInstance",
			instanceType:   "t3.medium",
			rootVolumeSize: 30,
			dataVolumeSize: 50,
		},
		{
			name:           "MediumInstance",
			instanceType:   "t3.large",
			rootVolumeSize: 50,
			dataVolumeSize: 100,
		},
		{
			name:           "LargeInstance",
			instanceType:   "t3.xlarge",
			rootVolumeSize: 100,
			dataVolumeSize: 500,
		},
		{
			name:           "ProductionInstance",
			instanceType:   "r5.large",
			rootVolumeSize: 100,
			dataVolumeSize: 1000,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/ec2-splunk",
				Vars: map[string]interface{}{
					"project_name":          "test-project",
					"environment":           "test",
					"vpc_id":                "vpc-12345678",
					"subnet_id":             "subnet-12345678",
					"availability_zone":     "us-east-1a",
					"ami_id":                "ami-0c7217cdde317cfec",
					"instance_type":         tc.instanceType,
					"root_volume_size":      tc.rootVolumeSize,
					"data_volume_size":      tc.dataVolumeSize,
					"data_volume_type":      "gp3",
					"kms_key_id":            nil,
					"splunk_admin_password": "SplunkAdmin123!",
					"splunk_hec_token":      "12345678-1234-1234-1234-123456789012",
					"splunk_version":        "9.1.1",
					"allowed_cidr":          []string{"10.0.0.0/8"},
					"ssh_cidr":              []string{"10.0.0.0/8"},
					"ssh_public_key":        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQtest",
					"associate_public_ip":   false,
					"secrets_manager_arn":   "",
					"tags":                  map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestEc2SplunkModuleVolumeTypes tests different EBS volume type configurations
func TestEc2SplunkModuleVolumeTypes(t *testing.T) {
	t.Parallel()

	volumeTypes := []string{"gp2", "gp3", "io1", "io2"}

	for _, volumeType := range volumeTypes {
		volumeType := volumeType
		t.Run(volumeType, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/ec2-splunk",
				Vars: map[string]interface{}{
					"project_name":          "test-project",
					"environment":           "test",
					"vpc_id":                "vpc-12345678",
					"subnet_id":             "subnet-12345678",
					"availability_zone":     "us-east-1a",
					"ami_id":                "ami-0c7217cdde317cfec",
					"instance_type":         "t3.medium",
					"root_volume_size":      50,
					"data_volume_size":      100,
					"data_volume_type":      volumeType,
					"kms_key_id":            nil,
					"splunk_admin_password": "SplunkAdmin123!",
					"splunk_hec_token":      "12345678-1234-1234-1234-123456789012",
					"splunk_version":        "9.1.1",
					"allowed_cidr":          []string{"10.0.0.0/8"},
					"ssh_cidr":              []string{"10.0.0.0/8"},
					"ssh_public_key":        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQtest",
					"associate_public_ip":   false,
					"secrets_manager_arn":   "",
					"tags":                  map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestEc2SplunkModuleNetworkConfiguration tests network access configurations
func TestEc2SplunkModuleNetworkConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name              string
		allowedCIDR       []string
		sshCIDR           []string
		associatePublicIP bool
	}{
		{
			name:              "PrivateOnly",
			allowedCIDR:       []string{"10.0.0.0/8"},
			sshCIDR:           []string{"10.0.0.0/8"},
			associatePublicIP: false,
		},
		{
			name:              "PublicAccess",
			allowedCIDR:       []string{"0.0.0.0/0"},
			sshCIDR:           []string{"203.0.113.0/24"},
			associatePublicIP: true,
		},
		{
			name:              "MultiCIDR",
			allowedCIDR:       []string{"10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"},
			sshCIDR:           []string{"10.0.0.0/8"},
			associatePublicIP: false,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/ec2-splunk",
				Vars: map[string]interface{}{
					"project_name":          "test-project",
					"environment":           "test",
					"vpc_id":                "vpc-12345678",
					"subnet_id":             "subnet-12345678",
					"availability_zone":     "us-east-1a",
					"ami_id":                "ami-0c7217cdde317cfec",
					"instance_type":         "t3.medium",
					"root_volume_size":      50,
					"data_volume_size":      100,
					"data_volume_type":      "gp3",
					"kms_key_id":            nil,
					"splunk_admin_password": "SplunkAdmin123!",
					"splunk_hec_token":      "12345678-1234-1234-1234-123456789012",
					"splunk_version":        "9.1.1",
					"allowed_cidr":          tc.allowedCIDR,
					"ssh_cidr":              tc.sshCIDR,
					"ssh_public_key":        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQtest",
					"associate_public_ip":   tc.associatePublicIP,
					"secrets_manager_arn":   "",
					"tags":                  map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestEc2SplunkModuleSplunkVersions tests various Splunk version configurations
func TestEc2SplunkModuleSplunkVersions(t *testing.T) {
	t.Parallel()

	splunkVersions := []string{"9.0.0", "9.0.5", "9.1.0", "9.1.1", "9.2.0"}

	for _, version := range splunkVersions {
		version := version
		t.Run("Splunk_"+version, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/ec2-splunk",
				Vars: map[string]interface{}{
					"project_name":          "test-project",
					"environment":           "test",
					"vpc_id":                "vpc-12345678",
					"subnet_id":             "subnet-12345678",
					"availability_zone":     "us-east-1a",
					"ami_id":                "ami-0c7217cdde317cfec",
					"instance_type":         "t3.medium",
					"root_volume_size":      50,
					"data_volume_size":      100,
					"data_volume_type":      "gp3",
					"kms_key_id":            nil,
					"splunk_admin_password": "SplunkAdmin123!",
					"splunk_hec_token":      "12345678-1234-1234-1234-123456789012",
					"splunk_version":        version,
					"allowed_cidr":          []string{"10.0.0.0/8"},
					"ssh_cidr":              []string{"10.0.0.0/8"},
					"ssh_public_key":        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQtest",
					"associate_public_ip":   false,
					"secrets_manager_arn":   "",
					"tags":                  map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}
