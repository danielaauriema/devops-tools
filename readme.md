
This project helps you setup your private/on-premise devops environment.

The goal is to make it a complete set of tools contaning at least:
- ***dns server***:  allow you to access your applications through an user friendly URI instead of the use of ip and port. This approach also helps you to escalate your server moving it to another location in a almost transparent way.
- ***vpn connection***: allow you to acess your private environment from anywhere with encripted connection.
- ***open LDAP repository***: allows you access different applications with the same login and password. It also make easy to add your friends and give them access to your applications.
- ***git server***: allow you to create your own projects and repositories to start your own CI/CD pipeline. 

# Quick Start

Add your user name and server address in ansible inventory hosts file:
```
./ansible/inventory/hosts.yml
```

Run then follqwing command to execute the project:
```
ansible-playbook ./ansible/server.yml -i ./ansible/inventory
```

# Going deeper in ansible-tools project

This project uses ansible to install all requrired software and configuration in the remote host.

## Basic tools

To run ansible playbooks, you first need a server with SSH connection. 
This project was been tested so far using DEBIAN 12, and it is the recommended operating system.

You also need some local storage for personalised configuration such as keys and certificates. By default this will be stored in the `data` folder that will be created in the project root folder. This folder is in `.gitignore` file.

You can define a different location by setting `local_data_path` variable. If it is not defined, it will be defined and created when executing the role `core\init`.

## UFW (Firewall)

This project uses ufw as a firewall. After being installed it will block all incoming requests, except by the port and address used by ansible to access the remote machine.

If you want to use a different one, you can set this up in the variables `ufw_ssh_port` and `ufw_ssh_address`. Be carefull to not lock you out of the server.

## Bind9 (DNS)

Bind9 is a free DNS server.
You can set your own domain in the variable `core_domain`. Default is `devops-tools.local`.

## Wireguard (VPN)

To setup up your own vpn, set the following variables if you want some customization:
- ***wg_network_prefix***: is the vpn address space. It has only the first 3 bytes and by default is `172.16.20`. This will be the base for clients and server addresses.
- ***wg_network_name***: this is the interface name in the server and the file name for clients. Default is `wg_vpn`.
- ***wg_server_port***: this is the port where the clients will connect.  Default is `51820`.
- ***wg_server_internal_addr***: This the server address in the vpn. Default is `"{{ wg_network_prefix }}.1"`. Exemple: `172.16.20.1`.

It will also setup the DNS server for you own DNS server. So, you can used personal URL's when connected through VPN.

Default DNS config is: `{{ wg_server_internal_addr }}, 8.8.8.8, 8.8.4.4"`
You can change to other servers by changing the value in `wg_client_dns`.

### Generating VPN keys

The role `wireguard/config` will generate all keys for clients and server. The keys are locally stored in the variable `wg_local_conf_path`. Default is `/data/wireguard`.

This role has a list of `key/pairs` containing respectively a name to identify the client and one `id`. The `id` will be used as a suffix to compose the client address.

### Installing the VPN

The role `wireguard\server` will install the application using the parameters generated by the config role. It will also set up the proper config in ufw.