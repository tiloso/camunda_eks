# Camunda platform setup on AWS EKS

## Overview
The goal is to create a maintainable setup of the Camunda 8 platform
on EKS that fulfills basic standards towards security, availability, and maintainability.


## Approach
The setup is based on AWS EKS and is being provisioned by Terraform. The implementation
tries to minimize the steps required to deploy Camunda 8.
Due to a [constraint](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#stacking-with-managed-kubernetes-cluster-resources)
of Terraform's Kubernetes and helm provider, the setup can't be accomplished in one
step but requires two.   
Topology of the EKS cluster: The worker nodes are placed in private subnets,
Kubernetes' API server is exposed publicly, but access to it is limited to a specified
origin IP. The data of workloads inside the cluster is stored encrypted at rest, and
the communication between clients and the ingress' load balancer is TLS encrypted.


## Provisioning of the Setup
1. Set custom terraform variables in both modules (`terraform.tfvars`).
  Although it's not a good practice, I included some example values I've used.
2. Provision the AWS network and EKS cluster
  ```
  cd infra/
  terraform init
  terraform apply
  ```
3. Step 2.) prints the NS DNS records of the DNS zone it provisioned. These need to
  be configured in the domain's root DNS zone or domain registrar. The step could
  be automated as well. To keep the setup flexible and allow using any
  registrar/ DNS management solution, I didn't include it.
4. Deploy Camunda platform
  ```
  cd k8s/
  terraform init
  terraform apply
  ```


## Design Decisions
**Automation**   
I decided to use Terraform to provision and configure EKS and Camunda. Over a _manual_
approach (AWS Console, eksctl, aws cli for AWS and, helm and kubectl for Kubernetes)
it has the following advantages:
- Reproducibility
- Low provisioning and maintenance effort
- Documentation through code
- Option to handle it like regular code (editor, version control, code reviews, linting, etc.)

Terraform is the most widely used, mature, and supported IaC tool (e.g. compared to Pulumi) and
allows to handle most steps (e.g. Cloudformation and helm would only be useable for a part
of the setup).

**Terraform AWS Provisioning**   
The provisioning of the AWS resources uses Terraform's AWS module. By using a
higher-level module, e.g. [terraform-aws-modules/eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
the configuration could be more concise.   
Advantages
- Less code/ concise: simplifies setup and
- Potentially improved maintainability
- Potentially implement secure defaults

Disadvantages   
- Introduces a dependency and additional layer between our config and AWS
- Increases supply chain risks
- Creates a dependency on another third-party (updates, security,...)

Think it depends on the context (e.g. trustworthiness of the module, complexity reduction,...),
whether the advantages or disadvantages of using a higher-level module outweigh.

**Validation**   
Apart from the static validation of the Terraform configuration, the Camunda platform
needs to be validated manually. In the future, it might be automated, e.g. with Terratest.

## Improvements / Outlook / Next Steps
### Open Issues / Missing Validation
- Authentication doesn't work seamlessly yet. Keycloak attempts to send the login's
  POST request using HTTP instead of HTTPS. Its current configuration seems to be incomplete.
  A workaround is to update the protocol from `http` to `https` in the login
  form action.
- Validation of the connection to Zeebe; the current ALB configuration might not support gRPC calls yet
- Adding Prometheus scrape annotations to all of Camunda's components

### Security
- Dive deeper into Camunda's best practices and configuration
- Depending on the specific requirements, the level of security and compliance can be increased, e.g. by implementing
  - Internal SSL encryption with a service mesh
  - Enabling the strict Pod Security Admission policy and making sure all workloads
    comply with it (e.g. no root user in the container, limit access to Linux capabilities,
    limit types of volumes that can be bound)
- Review tfsec's hotspots and decide whether to fix or ignore them

### Reliability
- Revisit the setup in regards to redundancy and distribution across failure domains, i.e. AWS' availability zones (pod anti-affinity policies, PodDisruptionBudgets)
- Deletion protection should be enabled for a production-like setup
- Backup and restore should be implemented and automated for Camunda's data stores

### Monitoring
- Implement log-forwarding to a central log management service (e.g. AWS Cloudwatch, Grafana Loki,..) with FluentD or Fluent bit
- Set up Grafana, configure Prometheus as its data source, and import Kubernetes and Camunda-specific dashboard

### Automation/ Maintainability
- The configuration of the Camunda platform can't be updated in its current form after it has been applied initially
- Automate Terraform execution, e.g. by executing it with a CI/CD pipeline, using Terraform Cloud, or a tool like Atlantis
- Refactor the Terraform root modules into modules that can be instantiated
