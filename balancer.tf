##################Таргет для веб сайто##########################
resource "yandex_lb_target_group" "web_tg" {
  name = "my-target-group"
  
  target {
    subnet_id = yandex_vpc_subnet.develop_a.id
    address   = yandex_compute_instance.web_a.network_interface.0.ip_address
  }
  
  target {
    subnet_id = yandex_vpc_subnet.develop_b.id
    address   = yandex_compute_instance.web_b.network_interface.0.ip_address
  }
}
#####################Таргет для Zabbix###############
resource "yandex_lb_target_group" "zabbix_tg" {
  name = "zabbix-target-group"

  target {
    subnet_id = yandex_vpc_subnet.public_zabbix.id
    address   = yandex_compute_instance.zabbix.network_interface.0.ip_address
  }
}

#####################Таргет для ELK###############
resource "yandex_lb_target_group" "elk_tg" {
  name = "elk-target-group"

  target {
    subnet_id = yandex_vpc_subnet.public_elk.id
    address   = yandex_compute_instance.elk.network_interface.0.ip_address
  }
}


resource "yandex_lb_network_load_balancer" "my_nlb" {
  name = "my-network-load-balancer"
  # Listener для Web (порт 80)
  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  # Listener для Zabbix (порт 8080)
  listener {
    name = "zabbix-listener"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }
#######elk
  listener {
    name = "elk-listener"
    port = 5601
    external_address_spec {
      ip_version = "ipv4"
    }
  }


  attached_target_group {
    target_group_id = yandex_lb_target_group.web_tg.id

    healthcheck {
      name = "web-healthcheck"
      interval = 2
      timeout = 1
      healthy_threshold = 2
      unhealthy_threshold = 2
      
      http_options {
        port = 80
        path = "/ping"
      }
    }
  }

  # Target group для Zabbix
  attached_target_group {
    target_group_id = yandex_lb_target_group.zabbix_tg.id

    healthcheck {
      name = "zabbix-healthcheck"
      interval = 2
      timeout = 1
      healthy_threshold = 2
      unhealthy_threshold = 2
      
      http_options {
        port = 8080  # Zabbix веб-интерфейс
        path = "/ping"   # Или "/zabbix" если Zabbix в поддиректории
      }
    }
  }

  # Target group для ELK
  attached_target_group {
    target_group_id = yandex_lb_target_group.elk_tg.id

    healthcheck {
      name = "elk-healthcheck"
      interval = 2
      timeout = 1
      healthy_threshold = 2
      unhealthy_threshold = 2
      
      http_options {
        port = 5601  # Zabbix веб-интерфейс
        path = "/api/status"   # Или "/zabbix" если Zabbix в поддиректории
      }
    }
  }
}




