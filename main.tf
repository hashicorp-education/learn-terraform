terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.73.0"
    }
  }

  required_version = ">= 0.15.0"
cloud { 
    organization = "cnelson01_test_org" 
    workspaces { 
      name = "gcptest" 
    } 
} 
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}


provider "google" {
  project = "engaged-hook-440719-g4"
  region  = "us-central1"
  zone    = "us-central1-c"
}


module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "3.3.0"

  project_id = "engaged-hook-440719-g4"

  activate_apis = [
    "compute.googleapis.com",
    "oslogin.googleapis.com"
  ]

  disable_services_on_destroy = false
  disable_dependent_services  = false
}# [START compute_basic_vm_parent_tag]
# [START compute_instances_create]

# Create a VM instance from a public image
# in the `default` VPC network and subnet

resource "google_compute_instance" "default" {
  name         = "my-vm"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2210-kinetic-amd64-v20230126"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}
# [END compute_instances_create]

# [START vpc_compute_basic_vm_custom_vpc_network]
resource "google_compute_network" "custom" {
  name                    = "my-network"
  auto_create_subnetworks = false
}
# [END vpc_compute_basic_vm_custom_vpc_network]

# [START vpc_compute_basic_vm_custom_vpc_subnet]
resource "google_compute_subnetwork" "custom" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west1"
  network       = google_compute_network.custom.id
}
# [END vpc_compute_basic_vm_custom_vpc_subnet]

# [START compute_instances_create_with_subnet]

# Create a VM in a custom VPC network and subnet

resource "google_compute_instance" "custom_subnet" {
  name         = "my-vm-instance"
  tags         = ["allow-ssh"]
  zone         = "europe-west1-b"
  machine_type = "e2-small"
  network_interface {
    network    = google_compute_network.custom.id
    subnetwork = google_compute_subnetwork.custom.id
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
}
# [END compute_instances_create_with_subnet]
# [END compute_basic_vm_parent_tag]
