provider "google" {
  project = "academic-moon-438709-k5"
  region  = "us-central1"
}

# Create a GKE Autopilot cluster
resource "google_container_cluster" "autopilot_cluster" {
  name     = "autopilot-helloworld-cluster"
  location = "us-central1"
  
  enable_autopilot = true

  # Autopilot doesn't require node configuration
}

# Grant permissions for GKE to use the Service Account for Autopilot
resource "google_container_cluster_iam_binding" "gke_permissions" {
  cluster = google_container_cluster.autopilot_cluster.name
  location = google_container_cluster.autopilot_cluster.location
  role = "roles/container.admin"
  members = [
    "serviceAccount:insole01rusts@icloud.com"
  ]
}

# Deploy a Hello World application in Kubernetes
resource "kubernetes_deployment" "helloworld_deployment" {
  metadata {
    name = "helloworld"
    labels = {
      app = "helloworld"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "helloworld"
      }
    }

    template {
      metadata {
        labels = {
          app = "helloworld"
        }
      }

      spec {
        container {
          name  = "helloworld"
          image = "gcr.io/google-samples/hello-app:1.0"

          ports {
            container_port = 8080
          }
        }
      }
    }
  }
}

# Expose the Hello World deployment as a service
resource "kubernetes_service" "helloworld_service" {
  metadata {
    name = "helloworld-service"
  }

  spec {
    selector = {
      app = "helloworld"
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 8080
    }
  }
}

provider "kubernetes" {
  host                   = google_container_cluster.autopilot_cluster.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.autopilot_cluster.master_auth.0.cluster_ca_certificate)
}
