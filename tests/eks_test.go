package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestEKSModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"

	network := deployVPC(t, awsRegion, "test-eks-vpc")
	defer terraform.Destroy(t, network.options)

	clusterName := fmt.Sprintf("test-eks-%s", random.UniqueId())

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/eks",
		Vars: map[string]interface{}{
			"cluster_name":       clusterName,
			"kubernetes_version": "1.30",
			"private_subnet_ids": network.privateSubnets,
			"public_subnet_ids":  network.publicSubnets,
			"node_groups": map[string]interface{}{
				"general": map[string]interface{}{
					"instance_types": []string{"t3.medium"},
					"desired_size":   1,
					"min_size":       1,
					"max_size":       2,
					"disk_size":      20,
				},
			},
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	clusterID := terraform.Output(t, terraformOptions, "cluster_id")
	require.NotEmpty(t, clusterID)

	endpoint := terraform.Output(t, terraformOptions, "cluster_endpoint")
	assert.Contains(t, endpoint, "https://", "cluster endpoint should be an HTTPS URL")

	clusterVersion := terraform.Output(t, terraformOptions, "cluster_version")
	assert.Equal(t, "1.30", clusterVersion)

	oidcARN := terraform.Output(t, terraformOptions, "oidc_provider_arn")
	assert.Contains(t, oidcARN, "oidc-provider", "IRSA OIDC provider should be created")

	nodeRoleARN := terraform.Output(t, terraformOptions, "node_role_arn")
	assert.Contains(t, nodeRoleARN, ":role/", "worker node IAM role should be created")
}
