locals {
  cluster_type = "hub-sandbox"
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

/*****************************************
  Enable GCP APIs
 *****************************************/

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.4"

  project_id = var.project_id

  activate_apis = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "container.googleapis.com",
    "storage-component.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
  ]
}

/*****************************************
  Create VPC Network
 *****************************************/

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}" = [
      {
        range_name    = var.ip_range_pods
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

/*****************************************
  Create GKE cluster
 *****************************************/

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 29.0"

  project_id                  = var.project_id
  name                        = "${local.cluster_type}-cluster${var.cluster_name_suffix}"
  #kubernetes_version	        = "1.30.1-gke.1156000"
  release_channel             = "RAPID"
  regional                    = false
  zones                       = var.zones
  network                     = var.network
  subnetwork                  = var.subnetwork
  ip_range_pods               = var.ip_range_pods
  ip_range_services           = var.ip_range_services
  create_service_account      = false
  service_account             = var.compute_engine_service_account
  enable_cost_allocation      = true
  enable_binary_authorization = var.enable_binary_authorization
  gcs_fuse_csi_driver         = true
  deletion_protection         = false
  config_connector            = true
  remove_default_node_pool    = true

  // Define the node pool configuration
  node_pools = [
    {
      name               = "simple-pool"
      machine_type       = "e2-standard-2"
      min_count          = 1         
      max_count          = 1         
      disk_size_gb       = 30        
      disk_type          = "pd-standard"
      auto_repair        = true
      auto_upgrade       = false
    }
  ]
}

/*****************************************
  Configure Workload Identity
 *****************************************/

resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = "projects/gke-sandbox-412119/serviceAccounts/superadmin@gke-sandbox-412119.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:gke-sandbox-412119.svc.id.goog[cnrm-system/cnrm-controller-manager]"
  ]
}
