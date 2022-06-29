provider "google" {
  #  credentials = file("terraform-348105-3a95cf2fec51.json")
  credentials = file("gcertifica-vpn-3d5c17cab3c9.json")
  project     = "gcertifica-vpn"
  region      = "southamerica-east1"
  zone        = "southamerica-east1-a"
}


# [START cloudvpn_ha_gcp_to_gcp]
resource "google_compute_ha_vpn_gateway" "gcertifica-vpc" {
  region   = "southamerica-east1"
  name     = "ha-vpn-1"
  network  = "gcertifica-vpc" //alterar para o nome da VPC já criada
}

resource "google_compute_ha_vpn_gateway" "gcertifica-vpc-unipar-prod" {
  region   = "southamerica-east1"
  name     = "ha-vpn-2"
  network  = "gcertifica-vpc-unipar-prod"
}

# resource "google_compute_network" "network1" {
#   name                    = "network1"
#   routing_mode            = "GLOBAL"
#   auto_create_subnetworks = false
# }

# resource "google_compute_network" "network2" {
#   name                    = "network2"
#   routing_mode            = "GLOBAL"
#   auto_create_subnetworks = false
# }

resource "google_compute_subnetwork" "subnet1_gcertifica-vpc" {
  name          = "subgertificavpc1"
  ip_cidr_range = "10.49.1.0/28"
  region        = "us-central1"
  network       = "gcertifica-vpc"
}

resource "google_compute_subnetwork" "subnet2_gcertifica-vpc" {
  name          = "subgcertificavpc2"
  ip_cidr_range = "10.49.2.0/28"
  region        = "southamerica-east1"
  network       = "gcertifica-vpc"
}

resource "google_compute_subnetwork" "subnet1_gcertifica-vpc-unipar-prod" {
  name          = "subgcertificavpcuniparprod3"
  ip_cidr_range = "192.168.1.0/24"
  region        = "us-central1"
  network       = "gcertifica-vpc-unipar-prod"
}

resource "google_compute_subnetwork" "subnet2_gcertifica-vpc-unipar-prod" {
  name          = "subgcertificavpcuniparprod4"
  ip_cidr_range = "192.168.2.0/24"
  region        = "us-east1"
  network       = "gcertifica-vpc-unipar-prod"
}

resource "google_compute_router" "routergcertifica" {
  name     = "ha-vpn-gcertifica"
  network  = "projects/gcertifica-vpn/global/networks/gcertifica-vpc"
  bgp {
    asn = 64514
  }
}

resource "google_compute_router" "routergcertifica-vpc-unipar-prod" {
  name     = "ha-vpn-gcertifica-vpc-unipar-prod"
  network  = "projects/gcertifica-vpn/global/networks/gcertifica-vpc-unipar-prod"
  bgp {
    asn = 64515
  }
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  name                  = "ha-vpn-tunnel1"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.gcertifica-vpc.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gcertifica-vpc-unipar-prod.id
  shared_secret         = "gendanken"
  router                = google_compute_router.routergcertifica.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name                  = "ha-vpn-tunnel2"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.gcertifica-vpc.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gcertifica-vpc-unipar-prod.id
  shared_secret         = "gendanken"
  router                = google_compute_router.routergcertifica.id
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "tunnel3" {
  name                  = "ha-vpn-tunnel3"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.gcertifica-vpc-unipar-prod.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gcertifica-vpc.id
  shared_secret         = "gendanken"
  router                = google_compute_router.routergcertifica-vpc-unipar-prod.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel4" {
  name                  = "ha-vpn-tunnel4"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.gcertifica-vpc-unipar-prod.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.gcertifica-vpc.id
  shared_secret         = "gendanken"
  router                = google_compute_router.routergcertifica-vpc-unipar-prod.id
  vpn_gateway_interface = 1
}

resource "google_compute_router_interface" "routergcertifica_interface1" {
  name       = "routergercertifica-to-interface1"
  router     = google_compute_router.routergcertifica.name
  region     = "southamerica-east1"
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "routergcertifica_peer1" {
  name                      = "router-gcertifica-peer1"
  router                    = google_compute_router.routergcertifica.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.routergcertifica_interface1.name
}

resource "google_compute_router_interface" "routergcertifica_interface2" {
  name       = "routergcertifica-to-interface2"
  router     = google_compute_router.routergcertifica.name
  region     = "southamerica-east1"
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "routergcertifica_peer2" {
  name                      = "router-gcertifica-peer2"
  router                    = google_compute_router.routergcertifica.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.1.1"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.routergcertifica_interface2.name
}

resource "google_compute_router_interface" "routergcertifica-vpc-unipar-prod_interface1" {
  name       = "router-gcertifica-vpc-unipar-prod-interface1"
  router     = google_compute_router.routergcertifica-vpc-unipar-prod.name
  region     = "southamerica-east1"
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3.name
}

resource "google_compute_router_peer" "routergcertifica-vpc-unipar-prod_peer1" {
  name                      = "routergcertifica-vpc-unipar-prod-peer1"
  router                    = google_compute_router.routergcertifica-vpc-unipar-prod.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.routergcertifica-vpc-unipar-prod_interface1.name
}

resource "google_compute_router_interface" "routergcertifica-vpc-unipar-prod_interface2" {
  name       = "router-gcertifica-vpc-unipar-prod-interface2"
  router     = google_compute_router.routergcertifica-vpc-unipar-prod.name
  region     = "southamerica-east1"
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel4.name
}

resource "google_compute_router_peer" "routergcertifica-vpc-unipar-prod_peer2" {
  name                      = "router-gcertifica-vpc-unipar-prod-peer2"
  router                    = google_compute_router.routergcertifica-vpc-unipar-prod.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.routergcertifica-vpc-unipar-prod_interface2.name
}
# [END cloudvpn_ha_gcp_to_gcp]