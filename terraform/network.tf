################
# Networking Config
################


# getting public network id for routing
data "openstack_networking_network_v2" "public" {
  name = "public"
}

#create a virtual network for this project
resource "openstack_networking_network_v2" "dcn_network" {
  name = "dcn_network"
  admin_state_up  = "true"
  tags = ["terraform", "dcn"]
}

#creating the virtual subnet
resource "openstack_networking_subnet_v2" "dcn_subnet1" {
  name = "dcn_subnet1"
  network_id  = "${openstack_networking_network_v2.dcn_network.id}"
  cidr  = "192.168.120.0/24"
  ip_version  = 4
  tags = ["terraform","dcn"]
}

# setting up virtual router for accessing the public network
resource "openstack_networking_router_v2" "dcn_router" {
  name = "dcn_router"
  admin_state_up  = true
  # id of public network at JS1/2
  external_network_id = data.openstack_networking_network_v2.public.id
  tags = ["terraform"]
}

# connect the routern to our dcn subnet
resource "openstack_networking_router_interface_v2" "dcn_router_interface_1" {
  router_id = "${openstack_networking_router_v2.dcn_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.dcn_subnet1.id}"
}
