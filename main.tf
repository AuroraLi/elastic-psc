provider "google" {
    project = var.project
  # Configuration options
}
provider "google-beta" {
    project = var.project
  # Configuration options
}

data "google_project" "project" {
  project_id = var.project
}


resource "google_compute_network" "network" {
  name = "elastic"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  project = var.project
}


resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.network.id
  private_ip_google_access = true
}





resource "google_compute_address" "psc_ilb_consumer_address" {
  name   = "psc-ilb-consumer-address"
  region = var.region

  subnetwork   = google_compute_subnetwork.subnet.name
  address_type = "INTERNAL"
}

resource "google_compute_forwarding_rule" "psc_ilb_consumer" {
  name   = "psc-elastic"
  region = var.region

  target                = "projects/cloud-production-168820/regions/us-central1/serviceAttachments/proxy-psc-production-us-central1-v1-attachment"
  load_balancing_scheme = "" # need to override EXTERNAL default when target is a service attachment
  network               = google_compute_network.network.name
  ip_address            = google_compute_address.psc_ilb_consumer_address.id
}


resource "google_dns_managed_zone" "elastic" {
  name        = "elastic-test"
  dns_name    = "${var.region}.gcp.cloud.es.io."
  description = "Example private DNS zone"
  labels = {
    foo = "bar"
  }

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.network.id
    }
  }
}

resource "google_dns_record_set" "elastic-test" {
  name         = "*.${var.region}.gcp.cloud.es.io."
  managed_zone = google_dns_managed_zone.elastic.name
  type         = "A"
  ttl          = 300
  rrdatas = [google_compute_address.psc_ilb_consumer_address.address]
}




variable "project" {
    type        = string
    description = "The project in which to place all new resources"
}

variable "region" {
    type        = string
    description = "region"
    default = "us-central1"
}
