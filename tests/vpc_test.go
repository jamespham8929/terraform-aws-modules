package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestVPCModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"
	uniqueID := random.UniqueId()
	name := fmt.Sprintf("test-vpc-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"name": name,
			"cidr": "10.0.0.0/16",
			"azs":  []string{"us-east-1a", "us-east-1b"},
			"private_subnets": []string{"10.0.1.0/24", "10.0.2.0/24"},
			"public_subnets":  []string{"10.0.101.0/24", "10.0.102.0/24"},
			"enable_nat_gateway": true,
			"single_nat_gateway": true,
			"enable_flow_logs":   false,
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

	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	require.NotEmpty(t, vpcID)

	vpc := aws.GetVpcById(t, vpcID, awsRegion)
	assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)

	privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.Len(t, privateSubnetIDs, 2)

	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.Len(t, publicSubnetIDs, 2)

	natGatewayIDs := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Len(t, natGatewayIDs, 1, "single_nat_gateway=true should create exactly one NAT gateway")
}

func TestVPCModuleNoNATGateway(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"
	uniqueID := random.UniqueId()
	name := fmt.Sprintf("test-vpc-nonat-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"name":               name,
			"cidr":               "10.1.0.0/16",
			"azs":                []string{"us-east-1a"},
			"private_subnets":    []string{"10.1.1.0/24"},
			"public_subnets":     []string{"10.1.101.0/24"},
			"enable_nat_gateway": false,
			"enable_flow_logs":   false,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	natGatewayIDs := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Empty(t, natGatewayIDs, "no NAT gateways should exist when enable_nat_gateway=false")
}
