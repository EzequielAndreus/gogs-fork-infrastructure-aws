package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestEcsModuleVariablesValidation validates that the ECS module has required variables
func TestEcsModuleVariablesValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/ecs",

		Vars: map[string]interface{}{
			"project_name":           "test-project",
			"environment":            "test",
			"aws_region":             "us-east-1",
			"vpc_id":                 "vpc-12345678",
			"public_subnet_ids":      []string{"subnet-pub1", "subnet-pub2"},
			"private_subnet_ids":     []string{"subnet-priv1", "subnet-priv2"},
			"docker_image":           "nginx:latest",
			"container_name":         "app",
			"container_port":         8080,
			"task_cpu":               256,
			"task_memory":            512,
			"desired_count":          2,
			"min_capacity":           1,
			"max_capacity":           4,
			"health_check_path":      "/health",
			"secrets_manager_arns":   []string{"arn:aws:secretsmanager:us-east-1:123456789012:secret:test"},
			"enable_container_insights": true,
			"log_retention_days":     30,
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

// TestEcsModuleContainerConfiguration tests various container configurations
func TestEcsModuleContainerConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name          string
		dockerImage   string
		containerPort int
		taskCPU       int
		taskMemory    int
	}{
		{
			name:          "NginxDefault",
			dockerImage:   "nginx:latest",
			containerPort: 80,
			taskCPU:       256,
			taskMemory:    512,
		},
		{
			name:          "CustomAppHighMemory",
			dockerImage:   "myuser/myapp:v1.0.0",
			containerPort: 8080,
			taskCPU:       512,
			taskMemory:    1024,
		},
		{
			name:          "HeavyWorkload",
			dockerImage:   "myuser/processor:latest",
			containerPort: 3000,
			taskCPU:       1024,
			taskMemory:    2048,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/ecs",
				Vars: map[string]interface{}{
					"project_name":           "test-project",
					"environment":            "test",
					"aws_region":             "us-east-1",
					"vpc_id":                 "vpc-12345678",
					"public_subnet_ids":      []string{"subnet-pub1"},
					"private_subnet_ids":     []string{"subnet-priv1"},
					"docker_image":           tc.dockerImage,
					"container_name":         "app",
					"container_port":         tc.containerPort,
					"task_cpu":               tc.taskCPU,
					"task_memory":            tc.taskMemory,
					"desired_count":          1,
					"min_capacity":           1,
					"max_capacity":           2,
					"health_check_path":      "/",
					"secrets_manager_arns":   []string{},
					"enable_container_insights": false,
					"log_retention_days":     7,
					"tags":                   map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestEcsModuleAutoScalingConfiguration tests auto-scaling configurations
func TestEcsModuleAutoScalingConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name         string
		desiredCount int
		minCapacity  int
		maxCapacity  int
	}{
		{
			name:         "SmallScale",
			desiredCount: 1,
			minCapacity:  1,
			maxCapacity:  2,
		},
		{
			name:         "MediumScale",
			desiredCount: 3,
			minCapacity:  2,
			maxCapacity:  6,
		},
		{
			name:         "LargeScale",
			desiredCount: 5,
			minCapacity:  3,
			maxCapacity:  10,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/ecs",
				Vars: map[string]interface{}{
					"project_name":           "test-project",
					"environment":            "test",
					"aws_region":             "us-east-1",
					"vpc_id":                 "vpc-12345678",
					"public_subnet_ids":      []string{"subnet-pub1", "subnet-pub2"},
					"private_subnet_ids":     []string{"subnet-priv1", "subnet-priv2"},
					"docker_image":           "nginx:latest",
					"container_name":         "app",
					"container_port":         80,
					"task_cpu":               256,
					"task_memory":            512,
					"desired_count":          tc.desiredCount,
					"min_capacity":           tc.minCapacity,
					"max_capacity":           tc.maxCapacity,
					"health_check_path":      "/",
					"secrets_manager_arns":   []string{},
					"enable_container_insights": true,
					"log_retention_days":     14,
					"tags":                   map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}

// TestEcsModuleDockerImageFormats tests various Docker image format inputs
func TestEcsModuleDockerImageFormats(t *testing.T) {
	t.Parallel()

	validImages := []string{
		"nginx",
		"nginx:latest",
		"nginx:1.25.0",
		"myuser/myapp",
		"myuser/myapp:v1.0.0",
		"myuser/myapp:latest",
		"ghcr.io/owner/image:tag",
	}

	for _, image := range validImages {
		image := image
		t.Run(image, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/ecs",
				Vars: map[string]interface{}{
					"project_name":           "test-project",
					"environment":            "test",
					"aws_region":             "us-east-1",
					"vpc_id":                 "vpc-12345678",
					"public_subnet_ids":      []string{"subnet-pub1"},
					"private_subnet_ids":     []string{"subnet-priv1"},
					"docker_image":           image,
					"container_name":         "app",
					"container_port":         80,
					"task_cpu":               256,
					"task_memory":            512,
					"desired_count":          1,
					"min_capacity":           1,
					"max_capacity":           2,
					"health_check_path":      "/",
					"secrets_manager_arns":   []string{},
					"enable_container_insights": false,
					"log_retention_days":     7,
					"tags":                   map[string]string{},
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			result := terraform.Validate(t, terraformOptions)
			assert.NotNil(t, result)
		})
	}
}
