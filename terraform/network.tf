# getting public network id for routing
data "openstack_networking_network_v2" "public" {
  name = "public"
}

#create a virtual network for this project
resource "openstack_networking_network_v2" "net" {
  name = "mytest-net"
  admin_state_up  = "true"
  tags = var.tags
}

#creating the virtual subnet
resource "openstack_networking_subnet_v2" "subnet" {
  name = "$mytest-subnet"
  network_id  = openstack_networking_network_v2.net.id
  cidr  = "192.168.120.0/24"
  ip_version  = 4
}

# router for accessing the public network
resource "openstack_networking_router_v2" "router" {
  name = "mytest-router"
  admin_state_up  = true
  external_network_id = data.openstack_networking_network_v2.public.id
  tags = var.tags
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}
