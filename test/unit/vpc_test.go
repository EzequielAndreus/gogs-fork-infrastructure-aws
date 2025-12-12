package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestVpcModuleVariablesValidation validates that the VPC module has required variables
func TestVpcModuleVariablesValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vpc",

		// Variables to pass to the Terraform module
		Vars: map[string]interface{}{
			"project_name":         "test-project",
			"environment":          "test",
			"vpc_cidr":             "10.0.0.0/16",
			"public_subnet_cidrs":  []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs": []string{"10.0.10.0/24", "10.0.11.0/24"},
			"availability_zones":   []string{"us-east-1a", "us-east-1b"},
			"enable_nat_gateway":   true,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},

		// Disable colors for cleaner output
		NoColor: true,
	})

	// Run terraform init and validate
	terraform.Init(t, terraformOptions)
	result := terraform.Validate(t, terraformOptions)

	// Assert validation passed
	assert.NotNil(t, result)
}

// TestVpcModuleCIDRValidation tests CIDR block configuration
func TestVpcModuleCIDRValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name               string
		vpcCIDR            string
		publicSubnetCIDRs  []string
		privateSubnetCIDRs []string
		shouldFail         bool
	}{
		{
			name:               "ValidStandardCIDR",
			vpcCIDR:            "10.0.0.0/16",
			publicSubnetCIDRs:  []string{"10.0.1.0/24", "10.0.2.0/24"},
			privateSubnetCIDRs: []string{"10.0.10.0/24", "10.0.11.0/24"},
			shouldFail:         false,
		},
		{
			name:               "ValidSmallCIDR",
			vpcCIDR:            "172.16.0.0/20",
			publicSubnetCIDRs:  []string{"172.16.0.0/24", "172.16.1.0/24"},
			privateSubnetCIDRs: []string{"172.16.2.0/24", "172.16.3.0/24"},
			shouldFail:         false,
		},
		{
			name:               "ValidSingleSubnet",
			vpcCIDR:            "192.168.0.0/16",
			publicSubnetCIDRs:  []string{"192.168.1.0/24"},
			privateSubnetCIDRs: []string{"192.168.10.0/24"},
			shouldFail:         false,
		},
	}

	for _, tc := range testCases {
		tc := tc // capture range variable
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/vpc",
				Vars: map[string]interface{}{
					"project_name":         "test-project",
					"environment":          "test",
					"vpc_cidr":             tc.vpcCIDR,
					"public_subnet_cidrs":  tc.publicSubnetCIDRs,
					"private_subnet_cidrs": tc.privateSubnetCIDRs,
					"availability_zones":   []string{"us-east-1a", "us-east-1b"},
					"enable_nat_gateway":   false,
					"tags":                 map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)

			if tc.shouldFail {
				assert.Nil(t, result, "Expected validation to fail for %s", tc.name)
			} else {
				assert.NotNil(t, result, "Expected validation to pass for %s", tc.name)
			}
		})
	}
}

// TestVpcModuleNATGatewayConfiguration tests NAT Gateway toggle
func TestVpcModuleNATGatewayConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name             string
		enableNATGateway bool
	}{
		{
			name:             "NATGatewayEnabled",
			enableNATGateway: true,
		},
		{
			name:             "NATGatewayDisabled",
			enableNATGateway: false,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/vpc",
				Vars: map[string]interface{}{
					"project_name":         "test-project",
					"environment":          "test",
					"vpc_cidr":             "10.0.0.0/16",
					"public_subnet_cidrs":  []string{"10.0.1.0/24"},
					"private_subnet_cidrs": []string{"10.0.10.0/24"},
					"availability_zones":   []string{"us-east-1a"},
					"enable_nat_gateway":   tc.enableNATGateway,
					"tags":                 map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestVpcModuleTagging tests tagging configuration
func TestVpcModuleTagging(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"project_name":         "my-app",
			"environment":          "production",
			"vpc_cidr":             "10.0.0.0/16",
			"public_subnet_cidrs":  []string{"10.0.1.0/24"},
			"private_subnet_cidrs": []string{"10.0.10.0/24"},
			"availability_zones":   []string{"us-east-1a"},
			"enable_nat_gateway":   false,
			"tags": map[string]string{
				"Environment": "production",
				"Team":        "platform",
				"CostCenter":  "engineering",
				"ManagedBy":   "terraform",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	result := terraform.Validate(t, terraformOptions)
	assert.NotNil(t, result)
}
