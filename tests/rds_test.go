package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRDSModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"

	network := deployVPC(t, awsRegion, "test-rds-vpc")
	defer terraform.Destroy(t, network.options)

	// RDS identifiers must be lowercase, so normalise the random suffix.
	identifier := fmt.Sprintf("test-rds-%s", strings.ToLower(random.UniqueId()))

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/rds",
		Vars: map[string]interface{}{
			"identifier":          identifier,
			"engine":              "postgres",
			"engine_version":      "15.4",
			"instance_class":      "db.t3.micro",
			"allocated_storage":   20,
			"db_name":             "testdb",
			"vpc_id":              network.vpcID,
			"subnet_ids":          network.privateSubnets,
			"allowed_cidr_blocks": []string{network.vpcCIDR},
			"multi_az":            false,
			"deletion_protection": false,
			"skip_final_snapshot": true,
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

	instanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	require.NotEmpty(t, instanceID)

	endpoint := terraform.Output(t, terraformOptions, "db_instance_endpoint")
	assert.Contains(t, endpoint, ":5432", "postgres endpoint should expose port 5432")

	port := terraform.Output(t, terraformOptions, "db_instance_port")
	assert.Equal(t, "5432", port)

	securityGroupID := terraform.Output(t, terraformOptions, "db_security_group_id")
	assert.NotEmpty(t, securityGroupID)

	// manage_master_password defaults to true, so a Secrets Manager secret holds
	// the generated credentials.
	secretARN := terraform.Output(t, terraformOptions, "master_password_secret_arn")
	assert.Contains(t, secretARN, "arn:aws:secretsmanager", "master password should be stored in Secrets Manager")
}
