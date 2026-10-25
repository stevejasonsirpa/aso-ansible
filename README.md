# ASO - Despliegue de servicios con Ansible

Roles de Ansible que despliegan de forma remota, sobre un **openSUSE 16.0 recién instalado**,
FTP, LAMP (Apache, PHP, phpMyAdmin, MariaDB), Samba y PostgreSQL.
Materia *Aplicación de Sistemas Operativos* (Ing. Grover Cussi).

## Pasos para el despliegue

Todo se ejecuta como **root en la máquina master**. La máquina destino solo necesita estar
encendida, en la misma red, con `sshd` activo y acceso de root por SSH (en openSUSE 16:
`/etc/ssh/sshd_config.d/root.conf` con `PermitRootLogin yes`).

### 1. Instalar las herramientas en el master

```bash
zypper -n install git ansible python313-passlib
```

En el destino, `scripts/preparar_destino.sh` habilita el acceso de root por SSH y muestra la IP.

### 2. Clonar el repositorio

```bash
git clone https://github.com/stevejasonsirpa/aso-ansible.git
cd aso-ansible
```

### 3. Configurar el archivo hosts

Poner la IP de la máquina destino en `inventory/hosts`:

```bash
nano inventory/hosts
```

```ini
[servidor]
destino ansible_host=192.168.X.X
```

### 4. Autorizar la llave SSH del master en el destino

El inventario no lleva usuario ni contraseña: Ansible entra con la llave SSH del master.

```bash
test -f /root/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
ssh-copy-id root@192.168.X.X
```

`ssh-copy-id` pide una sola vez la contraseña de root del destino.

### 5. Crear el vault con las contraseñas de los servicios

```bash
cp group_vars/servidor/vault.yml.ejemplo group_vars/servidor/vault.yml
nano group_vars/servidor/vault.yml
ansible-vault encrypt group_vars/servidor/vault.yml
```

En `nano` se reemplaza cada `CAMBIAR` por la contraseña que tendrá ese servicio.
`ansible-vault encrypt` pide inventar una clave para el vault. El archivo cifrado no se sube al
repositorio (`.gitignore`).

### 6. Ejecutar el despliegue

```bash
ansible-playbook site.yml --ask-vault-pass
```

Termina con `failed=0`. También se puede desplegar un solo servicio:

```bash
ansible-playbook site.yml --ask-vault-pass --tags postgresql
ansible-playbook site.yml --ask-vault-pass --tags lamp
```

### 7. Verificar

| Servicio | Prueba desde el master |
|---|---|
| FTP | `ftp 192.168.X.X` con `aso01` y la contraseña de Samba del vault |
| phpMyAdmin | Navegador: `http://192.168.X.X/phpmyadmin`, usuario `root` |
| Samba | `smbclient //192.168.X.X/files -U aso01`, `put` de un archivo, y en el destino `ls -l /opt/files` muestra `-rwxr-----` |
| PostgreSQL | `psql "host=192.168.X.X dbname=aso_pg user=aso_pg_admin sslmode=require"` conecta; con `sslmode=disable` se rechaza |

## Roles

| Rol | Qué hace | Plantilla |
|---|---|---|
| `base` | Bloquea PackageKit (que traba a zypper), activa firewalld y resuelve el nombre del host | |
| `vsftpd` | FTP con usuarios enjaulados (`chroot`), log de transferencias y puertos pasivos | `vsftpd.conf.j2` |
| `apache` | Apache 2 con HTTP abierto en el firewall | |
| `php` | PHP 8 y su módulo para Apache | |
| `phpmyadmin` | phpMyAdmin publicado en `/phpmyadmin` | `phpMyAdmin.conf` |
| `mariadb` | Contraseña de root, sin usuarios anónimos ni base de prueba, base `aso_db` y usuario `aso_admin` | |
| `samba` | Grupo `asogrupo`, usuarios `aso01` y `aso02` (sistema y Samba), `/opt/files` y recurso `[files]` con `create mask 0740` | `smb.conf.j2` |
| `postgresql` | PostgreSQL, `php8-pgsql`, contraseña de `postgres`, base `aso_pg`, usuario `aso_pg_admin` y conexión remota solo cifrada (SSL + scram-sha-256) | `pg_hba.conf.j2` |

## Tiempo de respuesta

`ansible.cfg` activa *pipelining*, conexiones SSH persistentes (`ControlPersist`), caché de facts,
`gather_subset = min` y `profile_tasks` para medir cada tarea. Una segunda ejecución sin cambios
termina en segundos con `changed=0`.
