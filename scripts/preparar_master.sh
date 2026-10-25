#!/bin/bash
set -e
if [ "$(id -u)" -ne 0 ]; then echo "Ejecutar como root: su -"; exit 1; fi
zypper -n install git ansible python313-passlib
test -f /root/.ssh/id_ed25519 || ssh-keygen -q -t ed25519 -N "" -f /root/.ssh/id_ed25519
echo
echo "Master listo: $(ansible --version | head -1)"
echo "Siguiente paso: ssh-copy-id root@IP_DEL_DESTINO"
