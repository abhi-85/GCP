variable developer_project {


        default = "dev-project-817103"
}


variable production_project {


        default = "driven-strength-888789"
}
resource "google_compute_network" "vpc1"{
  name="abhi-vpc-1"
  project = var.production_project
  routing_mode="GLOBAL"
  auto_create_subnetworks="false"


}

resource "google_compute_network" "vpc2"{
name="abhi-vpc-2"
project = var.developer_project
 routing_mode="GLOBAL"
auto_create_subnetworks="false"


}

resource "google_compute_subnetwork" "subnet2"{
ip_cidr_range="10.10.12.0/24"
name="abhi-subnet-2"
network =google_compute_network.vpc2.name
project=var.developer_project
region="us-west1"


}
resource "google_compute_subnetwork" "subnet1"{
ip_cidr_range="10.10.11.0/24"
name="abhi-subnet-1"
network = google_compute_network.vpc1.name
project= var.production_project
region="us-west1"


}
resource "google_compute_firewall" "default" {
  name    = "abhi-firewall"
  network = google_compute_network.vpc1.name
  project= var.production_project
  allow {
    protocol = "icmp"
  }


  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000","22"]
  }


  source_tags = ["web"]
  source_ranges=["0.0.0.0/0"]
}

resource "google_compute_firewall" "default1" {
  name    = "abhi-firewall"
  network = google_compute_network.vpc2.name
  project = var.developer_project


  allow {
    protocol = "icmp"
  }


  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000","22"]
  }


  source_tags = ["web"]
  source_ranges=["0.0.0.0/0"]
}
resource "google_compute_network_peering" "peering1" {
  name         = "peering-test"
  network      = google_compute_network.vpc1.id
  peer_network = google_compute_network.vpc2.id
  
}
resource "google_compute_network_peering" "peering2" {
  name         = "peering-test"
  network      = google_compute_network.vpc2.id
  peer_network = google_compute_network.vpc1.id


}
resource "google_compute_instance" "default22" {
  name         = "myos1"
  machine_type = "n1-standard-1"
  zone         = "us-west1-c"
  project=var.production_project
  tags = ["foo", "bar"]


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
network_interface {
    network = google_compute_network.vpc1.name
    subnetwork=google_compute_subnetwork.subnet1.name
    subnetwork_project="driven-strength-888789"
     access_config{
     }
  
  }
}
resource "google_compute_instance" "default2" {
  name         = "myos1"
  machine_type = "n1-standard-1"
  zone         = "us-west1-c"
  project="dev-project-817103"
  tags = ["foo", "bar"]


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
network_interface {
    network = google_compute_network.vpc2.name
    subnetwork=google_compute_subnetwork.subnet2.name
    subnetwork_project="dev-project-817103"
     access_config{


}
}
}
resource "google_container_cluster" "primary" {
  name               = "abhi-cluster"
  location           = "us-central1-a"
  initial_node_count = 3
  project=var.developer_project
  master_auth {
    username = ""
    password = ""


    client_certificate_config {
      issue_client_certificate = false
    }
  }


  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]


    metadata = {
      disable-legacy-endpoints = "true"
    }


    labels = {
      app = "wordpress"
    }


    tags = ["website", "wordpress"]
  }


  timeouts {
    create = "30m"
    update = "40m"
  }




}
resource "null_resource" "nullremote1"  {
depends_on=[google_container_cluster.primary] 
provisioner "local-exec" {
            command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location}  --project ${google_container_cluster.primary.project}"
        }




}
resource "kubernetes_service" "example" {


depends_on=[null_resource.nullremote1]  


metadata {
    name = "terra-example"
  }
  spec {
    selector = {
      app = "${kubernetes_pod.example.metadata.0.labels.app}"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 80
    }


    type = "LoadBalancer"
  }
}


resource "kubernetes_pod" "example" {


depends_on=[null_resource.nullremote1] 
metadata {
    name = "myword"
    labels = {
      app = "MyApp"
    }
  }


  spec {
    container {
      image = "wordpress"
      name  = "example"
    }
  }
}


output "wordpressip" {
          value = kubernetes_service.example.load_balancer_ingress
  

}
resource "google_sql_database" "database" {
  name     = "abhi-database"
  instance = google_sql_database_instance.master.name
  project=var.production_project
}


resource "google_sql_database_instance" "master" {
  name             = "instance15"
  database_version = "MYSQL_5_7"
  region           = "us-central1"
 
  project=var.production_project


  settings {
    
    tier = "db-f1-micro"
    
    
ip_configuration{
ipv4_enabled ="true"


authorized_networks{
name="public network"
value="0.0.0.0/0"
}
}


  }
}

resource "google_sql_user" "user" {
  name     = "abhi"
  instance = google_sql_database_instance.master.name
project=var.production_project
 
  password = "redhat"
}
