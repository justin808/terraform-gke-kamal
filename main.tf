terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = "kamal-demo-444506"
  region  = "us-central1"
}

# Create a custom VPC
resource "google_compute_network" "vpc_network" {
  name = "kamal-vpc"
}

# Create a custom subnetwork with secondary ranges for pods and services
resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "kamal-subnet"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.self_link
  ip_cidr_range = "10.0.0.0/16"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Create the GKE cluster
resource "google_container_cluster" "kamal_test_cluster" {
  name               = "kamal-test-cluster"
  location           = "us-central1"
  initial_node_count = 1  # Required for cluster setup

  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.vpc_subnet.name

  remove_default_node_pool = true

  # Enable IP aliasing
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }
}

# Create a custom node pool
resource "google_container_node_pool" "default_node_pool" {
  cluster  = google_container_cluster.kamal_test_cluster.name
  location = google_container_cluster.kamal_test_cluster.location

  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type = "e2-micro"
    disk_size_gb = 10
    preemptible  = true

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
