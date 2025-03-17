resource "google_compute_address" "ip-address" {
  name = "ipv4-address"
  region = "europe-west1"
}

resource "google_compute_instance" "this" {
  name                      = "tecweb-instance"
  machine_type              = "e2-medium"
  zone                      = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "custom-vpc"
    subnetwork = "subnetwork"
    access_config {
      nat_ip = google_compute_address.ip-address.address
    }
  }
  
  metadata_startup_script = templatefile("${path.module}/startup.sh.tpl", {
    server_ip = google_compute_address.ip-address.address
    server_domain = "outofstorage.pt"
  })
  
  tags = ["https-server"]
}