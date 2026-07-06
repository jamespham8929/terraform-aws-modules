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

func TestALBModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"

	network := deployVPC(t, awsRegion, "test-alb-vpc")
	defer terraform.Destroy(t, network.options)

	// ALB names are capped at 32 characters and must be lowercase.
	name := fmt.Sprintf("test-alb-%s", strings.ToLower(random.UniqueId()))

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/alb",
		Vars: map[string]interface{}{
			"name":                       name,
			"vpc_id":                     network.vpcID,
			"subnet_ids":                 network.publicSubnets,
			"enable_deletion_protection": false,
			"target_groups": map[string]interface{}{
				"app": map[string]interface{}{
					"port":              8080,
					"target_type":       "ip",
					"health_check_path": "/health",
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

	albARN := terraform.Output(t, terraformOptions, "alb_arn")
	require.NotEmpty(t, albARN)

	dnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	assert.Contains(t, dnsName, "elb.amazonaws.com", "ALB should publish an ELB DNS name")

	// An HTTP listener always exists; it redirects to HTTPS.
	httpListenerARN := terraform.Output(t, terraformOptions, "http_listener_arn")
	assert.NotEmpty(t, httpListenerARN)

	targetGroupARNs := terraform.OutputMap(t, terraformOptions, "target_group_arns")
	assert.Contains(t, targetGroupARNs, "app", "the app target group should be created")
}
