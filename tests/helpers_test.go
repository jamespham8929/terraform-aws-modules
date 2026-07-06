package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// vpcNetwork holds the VPC module outputs that the EKS, RDS, and ALB tests need
// to stand up their resources.
type vpcNetwork struct {
	options        *terraform.Options
	vpcID          string
	vpcCIDR        string
	privateSubnets []string
	publicSubnets  []string
}

// deployVPC applies the VPC module so a dependent module has real networking to
// attach to. The caller owns teardown and must defer terraform.Destroy on the
// returned options, registering it before it applies the dependent module so
// the VPC is destroyed last.
func deployVPC(t *testing.T, region, prefix string) vpcNetwork {
	name := fmt.Sprintf("%s-%s", prefix, random.UniqueId())

	options := &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"name":               name,
			"cidr":               "10.20.0.0/16",
			"azs":                []string{region + "a", region + "b"},
			"private_subnets":    []string{"10.20.1.0/24", "10.20.2.0/24"},
			"public_subnets":     []string{"10.20.101.0/24", "10.20.102.0/24"},
			"enable_nat_gateway": true,
			"single_nat_gateway": true,
			"enable_flow_logs":   false,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	}

	terraform.InitAndApply(t, options)

	return vpcNetwork{
		options:        options,
		vpcID:          terraform.Output(t, options, "vpc_id"),
		vpcCIDR:        terraform.Output(t, options, "vpc_cidr_block"),
		privateSubnets: terraform.OutputList(t, options, "private_subnet_ids"),
		publicSubnets:  terraform.OutputList(t, options, "public_subnet_ids"),
	}
}
