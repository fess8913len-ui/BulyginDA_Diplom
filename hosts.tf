
#считываем данные об образе ОС
data "yandex_compute_image" "centos_stream_9" {
  family = "centos-stream-9-oslogin"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion" #Имя ВМ в облачной консоли
  hostname    = "bastion" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos_stream_9.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

#  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_bastion.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }
}

resource "yandex_compute_instance" "elk" {
  name        = "elk" #Имя ВМ в облачной консоли
  hostname    = "elk" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 6
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos_stream_9.image_id
      type     = "network-hdd"
      size     = 40
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

#  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_elk.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = true
    security_group_ids = [yandex_vpc_security_group.elk.id]
  }
}




resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix" #Имя ВМ в облачной консоли
  hostname    = "zabbix" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos_stream_9.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

#  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_zabbix.id #зона ВМ должна совпадать с зоной subnet!!!
    nat                = false
    security_group_ids = [yandex_vpc_security_group.zabbix.id]
  }
}


resource "yandex_compute_instance" "web_a" {
  name        = "web-a" #Имя ВМ в облачной консоли
  hostname    = "web-a" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!


  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos_stream_9.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

#  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }
}

resource "yandex_compute_instance" "web_b" {
  name        = "web-b" #Имя ВМ в облачной консоли
  hostname    = "web-b" #формирует FDQN имя хоста, без hostname будет сгенрировано случаное имя.
  platform_id = "standard-v3"
  zone        = "ru-central1-b" #зона ВМ должна совпадать с зоной subnet!!!

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos_stream_9.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

#  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]

  }
}


locals {
  # Получаем IP адрес из первого listener'а
  lb_ip = [
    for listener in yandex_lb_network_load_balancer.my_nlb.listener :
    [
      for spec in listener.external_address_spec :
      spec.address
    ][0]
  ][0]
}

resource "local_file" "inventory" {
  content  = <<-XYZ
[bastion]
bastion ansible_host=${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

[webservers]
web-a ansible_host=${yandex_compute_instance.web_a.network_interface.0.ip_address}
web-b ansible_host=${yandex_compute_instance.web_b.network_interface.0.ip_address}

[zabbix]
zabbix ansible_host=${yandex_compute_instance.zabbix.network_interface.0.ip_address}

[elk]
elk ansible_host=${yandex_compute_instance.elk.network_interface.0.ip_address}


[webservers:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -i ~/.ssh/for_yandex -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'

[zabbix:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -i ~/.ssh/for_yandex -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'

[elk:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -i ~/.ssh/for_yandex -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'


[all:vars]
ansible_user = user
ansible_ssh_private_key_file = ~/.ssh/for_yandex
XYZ
  filename = "./hosts.ini"
}

# ==================== ИНФОРМАЦИЯ О БАЛАНСИРОВЩИКЕ ====================
resource "local_file" "lb_info" {
  content  = <<-XYZ
# Load Balancer Information
LB_IP=${local.lb_ip}
LB_WEB_URL=http://${local.lb_ip}:80
LB_ZABBIX_URL=http://${local.lb_ip}:8080

# Для проверки:
# curl $${LB_WEB_URL}/ping
# curl $${LB_ZABBIX_URL}/
XYZ
  filename = "./lb_info.txt"
}