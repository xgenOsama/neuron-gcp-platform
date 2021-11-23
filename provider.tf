# Specify the provider (GCP, AWS, Azure)
provider "google" {
  credentials = file("credentials.json")
  project     = var.project_name
  region      = var.region
}

terraform {
  backend "gcs" {
    bucket  = "lab-project-vodafone-tf-state"
    prefix  = "terraform/state"
  }
}

resource "google_project_service" "project" {
  project = var.project_name
  service = "compute.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

resource "google_project_service" "gcp_resource_manager_api" {
  project = var.project_name
  service = "cloudresourcemanager.googleapis.com"
  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project_name

  service = "cloudresourcemanager.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}
