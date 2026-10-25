#!/bin/bash
set -e
if [ "$(id -u)" -ne 0 ]; then echo "Ejecutar como root: su -"; exit 1; fi
mkdir -p /etc/ssh/sshd_config.d
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/10-root.conf
systemctl enable --now sshd
systemctl restart sshd
if systemctl is-active --quiet firewalld; then
  firewall-cmd -q --permanent --add-service=ssh
  firewall-cmd -q --reload
fi
echo
echo "Destino listo. Acceso de root por SSH: $(sshd -T | grep -i '^permitrootlogin')"
echo "IP de esta maquina (ponerla en inventory/hosts del master):"
ip -4 -o addr show scope global | awk '{print "  " $2 ": " $4}'
