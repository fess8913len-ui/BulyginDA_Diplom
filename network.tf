#создаем облачную сеть
resource "yandex_vpc_network" "develop" {
  name = "develop-fops-${var.flow}"
}

##################BASTION#####################
resource "yandex_vpc_subnet" "public_bastion" {
  name           = "public-bastion-${var.flow}"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.1.0/24"]
# route_table_id = yandex_vpc_route_table.rt.id
}
#############Zabbix###########################
resource "yandex_vpc_subnet" "public_zabbix" {
  name           = "public-zabbix-${var.flow}"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}
################ELK###########################
resource "yandex_vpc_subnet" "public_elk" {
  name           = "public-elk-${var.flow}"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.3.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}


############ WEB A ##########################
resource "yandex_vpc_subnet" "develop_a" {
  name           = "develop-fops-${var.flow}-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

################### WEB B #######################
resource "yandex_vpc_subnet" "develop_b" {
  name           = "develop-fops-${var.flow}-ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["192.168.2.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

################ NAT ########################
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "fops-gateway-${var.flow}"
  shared_egress_gateway {}
}

############# NAT ROUTE ########################
resource "yandex_vpc_route_table" "rt" {
  name       = "fops-route-table-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

###################firewall###################

resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  ingress {
    description    = "Allow Zabbix server port"
    protocol       = "TCP"
    v4_cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
    port           = 10050
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

resource "yandex_vpc_security_group" "zabbix" {
  name       = "zabbix-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }
  # SSH только от Bastion
  ingress {
    description    = "Allow SSH from bastion"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.0.1.0/24"]  # Только из подсети Bastion!
  }
  # Zabbix Server порт для агентов (если нужно)
  ingress {
    description    = "Allow Zabbix server port"
    protocol       = "TCP"
    v4_cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
    port           = 10051
  }
  ingress {
    description    = "Zabbix Agent from Zabbix Server"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.0.2.0/24"]  # Подсеть Zabbix Server
  }
  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

resource "yandex_vpc_security_group" "elk" {
  name       = "elk-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    description    = "Allow Kibana WEB"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }
  # SSH только от Bastion
  ingress {
    description    = "Allow SSH from bastion"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.0.1.0/24"]  # Только из подсети Bastion!
  }
  ingress {
    description    = "LOGSTASH"
    protocol       = "TCP"
    port           = 5044
    v4_cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]  # Подсеть Zabbix Server
  }


  ingress {
    description    = "Zabbix Agent from Zabbix Server"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.0.2.0/24"]  # Подсеть Zabbix Server
  }
  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}


##Внутренняя сеть
resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id
  ingress {
    description    = "Allow 192.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["192.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg-${var.flow}"
  network_id = yandex_vpc_network.develop.id

  # HTTP только от балансировщика (внутренние сети)
  ingress {
    description    = "Allow HTTP from load balancer"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SSH только от Bastion
  ingress {
    description    = "Allow SSH from bastion"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.0.1.0/24"]  # Только из подсети Bastion!
  }

  ingress {
    description    = "Zabbix Agent from Zabbix Server"
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.0.2.0/24"]  # Подсеть Zabbix Server
  }
  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}