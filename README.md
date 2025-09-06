# GKE Sandbox Hub Cluster

This Terraform configuration creates a comprehensive Google Kubernetes Engine (GKE) sandbox environment with hub configuration, including VPC networking, Workload Identity, Config Connector, and additional GCP services integration.

## Architecture Overview

This configuration provisions the following infrastructure:

- **VPC Network**: Custom VPC with a single subnet and secondary IP ranges for pods and services
- **GKE Cluster**: Zonal cluster with Config Connector enabled for managing GCP resources from Kubernetes
- **Workload Identity**: Configured to allow the Config Connector service account to manage GCP resources
- **Node Pool**: Single node pool with e2-standard-2 instances
- **GCP APIs**: Automatically enables required APIs for container, compute, IAM, and other services

## Key Features

- **Config Connector**: Enables management of GCP resources directly from Kubernetes
- **Workload Identity**: Secure authentication between GKE and GCP services
- **GCS Fuse CSI Driver**: Enables mounting Google Cloud Storage buckets as volumes
- **Cost Allocation**: Enabled for tracking resource costs
- **Binary Authorization**: Optional admission controller for container image verification
- **Auto-scaling**: Node pool configured with auto-repair and auto-upgrade
- **State Management**: Remote state stored in Google Cloud Storage
- **GitHub Actions**: Automated Terraform destroy workflow for infrastructure cleanup

## GitHub Actions

This repository includes a GitHub Actions workflow for automated infrastructure management:

### Terraform Destroy Workflow

The `.github/workflows/tf-destroy.yaml` workflow provides:

- **Manual Trigger**: Can be triggered manually via GitHub Actions UI (`workflow_dispatch`)
- **Terraform Setup**: Automatically installs and configures Terraform CLI
- **Authentication**: Uses `GOOGLE_CREDENTIALS` secret for GCP authentication
- **Destroy Process**: 
  - Runs `terraform init` to initialize the working directory
  - Executes `terraform plan -destroy` to preview destruction
  - Applies `terraform apply -destroy -auto-approve` when run on main branch

### Required Secrets

Configure the following secret in your GitHub repository settings:

- `GOOGLE_CREDENTIALS`: Service account key JSON for GCP authentication

### Usage

1. Go to the "Actions" tab in your GitHub repository
2. Select "Terraform Destroy" workflow
3. Click "Run workflow" to manually trigger the destroy process
4. The workflow will destroy all infrastructure resources

**⚠️ Warning**: This workflow will permanently destroy all infrastructure. Use with caution!

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | The project ID to host the cluster in | `string` | n/a | yes |
| cluster\_name\_suffix | A suffix to append to the default cluster name | `string` | `""` | no |
| region | The region to host the cluster in | `string` | n/a | yes |
| zones | The zones to host the cluster in | `list(string)` | n/a | yes |
| network | The VPC network to host the cluster in | `string` | n/a | yes |
| subnetwork | The subnetwork to host the cluster in | `string` | n/a | yes |
| ip\_range\_pods | The secondary ip range to use for pods | `string` | n/a | yes |
| ip\_range\_services | The secondary ip range to use for services | `string` | n/a | yes |
| compute\_engine\_service\_account | Service account to associate to the nodes in the cluster | `string` | n/a | yes |
| enable\_binary\_authorization | Enable BinAuthZ Admission controller | `bool` | `false` | no |
| tf\_state\_bucket | GCS bucket for storing Terraform state | `string` | n/a | yes |
| subnet\_ip | IP range for the subnet | `string` | `"10.10.10.0/24"` | no |

## Outputs

| Name | Description |
|------|-------------|
| kubernetes\_endpoint | The GKE cluster endpoint (sensitive) |
| client\_token | Base64 encoded access token for cluster authentication (sensitive) |
| ca\_certificate | The cluster's CA certificate (sensitive) |
| service\_account | The default service account used for running nodes |
| project\_id | The project ID hosting the cluster |
| region | The region where the cluster is located |
| cluster\_name | The name of the GKE cluster |
| network | The VPC network name |
| subnetwork | The subnetwork name |
| location | The cluster location |
| ip\_range\_pods | The secondary IP range used for pods |
| ip\_range\_services | The secondary IP range used for services |
| zones | List of zones in which the cluster resides |
| master\_kubernetes\_version | The master Kubernetes version |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Prerequisites

- Google Cloud SDK installed and configured
- Terraform >= 0.13 installed
- A GCP project with billing enabled
- Appropriate IAM permissions to create GKE clusters and VPC networks
- A GCS bucket for storing Terraform state (configured in `versions.tf`)

## Configuration

1. **Update `terraform.tfvars`** with your specific values:
   ```hcl
   project_id = "your-project-id"
   region     = "us-east1"
   zones      = ["us-east1-b"]
   compute_engine_service_account = "your-service-account@your-project.iam.gserviceaccount.com"
   ip_range_pods   = "pods"
   ip_range_services = "services"
   network = "compute-network"
   subnetwork = "gke-subnet"
   tf_state_bucket = "your-tfstate-bucket"
   ```

2. **Update the Workload Identity binding** in `main.tf` (lines 117-123) with your actual project ID and service account.

3. **Ensure the GCS bucket exists** for Terraform state storage.

## Usage

To provision this infrastructure, run the following from within this directory:

```bash
# Initialize Terraform and download providers
terraform init

# Review the infrastructure plan
terraform plan

# Apply the infrastructure
terraform apply

# Connect to the cluster (after apply completes)
gcloud container clusters get-credentials hub-sandbox-cluster --region us-east1 --project your-project-id

# Verify Config Connector is running
kubectl get pods -n cnrm-system
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Post-Deployment

After successful deployment:

1. **Verify Config Connector**: Check that the Config Connector pods are running in the `cnrm-system` namespace
2. **Test Workload Identity**: Deploy a workload that uses the Config Connector service account
3. **Access GCS**: Use the GCS Fuse CSI driver to mount Cloud Storage buckets as volumes

## Network Configuration

- **VPC CIDR**: 10.0.0.0/17
- **Pod IP Range**: 192.168.0.0/18
- **Service IP Range**: 192.168.64.0/18
- **Node Pool**: e2-standard-2 instances with 30GB standard persistent disks
