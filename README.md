# Grupo 12 — Despliegue con Ansible en openSUSE 16

Desde una máquina **master** instala y configura, en una máquina **destino vacía**:
FTP, Apache + PHP + phpMyAdmin + MariaDB, Samba y PostgreSQL.

## Pasos para ejecutar

Todo como **root en el master**.

En el **destino** solo hace falta permitir root por SSH (una vez):

```bash
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/10-root.conf
systemctl restart sshd
```

**1. Instalar herramientas**

```bash
zypper -n install git ansible python313-passlib
```

**2. Clonar el repositorio**

```bash
git clone https://github.com/stevejasonsirpa/aso-ansible.git
cd aso-ansible
```

**3. Poner la IP del destino en el archivo hosts**

```bash
nano inventory/hosts
```

```ini
[servidor]
destino ansible_host=IP_DEL_DESTINO
```

**4. Copiar la llave SSH al destino** (pide la contraseña de root del destino una vez)

```bash
ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
ssh-copy-id root@IP_DEL_DESTINO
```

Si `ssh-keygen` pregunta `Overwrite`, responder `n`.

**5. Crear el archivo de contraseñas cifrado (vault)**

```bash
cp group_vars/servidor/vault.yml.ejemplo group_vars/servidor/vault.yml
nano group_vars/servidor/vault.yml
ansible-vault encrypt group_vars/servidor/vault.yml
```

En `nano` se cambia cada `CAMBIAR` por una contraseña. `ansible-vault encrypt` pide inventar una clave.

**6. Ejecutar**

```bash
ansible-playbook site.yml --ask-vault-pass
```

Resultado esperado: `failed=0` (unos 4 minutos). Si se ejecuta otra vez: `changed=0` en segundos.

## Comprobar

| Servicio | Prueba |
|---|---|
| phpMyAdmin | Navegador: `http://IP_DEL_DESTINO/phpmyadmin` (usuario `root`) |
| FTP | `ftp IP_DEL_DESTINO` (usuario `aso01`) |
| Samba | `smbclient //IP_DEL_DESTINO/files -U aso01`; los archivos quedan `-rwxr-----` (create mask 0740) |
| PostgreSQL | `psql "host=IP_DEL_DESTINO dbname=aso_pg user=aso_pg_admin sslmode=require"`; con `sslmode=disable` se rechaza |

### Usuarios y contraseñas

Las contraseñas son las que se escribieron en el vault (paso 5):

| Para entrar a | Usuario | Contraseña (variable del vault) |
|---|---|---|
| phpMyAdmin / MariaDB (administrador) | `root` | `vault_mariadb_root_password` |
| phpMyAdmin / MariaDB (usuario de la base `aso_db`) | `aso_admin` | `vault_mariadb_app_password` |
| FTP y Samba | `aso01` o `aso02` | `vault_samba_password` |
| PostgreSQL (administrador) | `postgres` | `vault_postgresql_postgres_password` |
| PostgreSQL (usuario de la base `aso_pg`) | `aso_pg_admin` | `vault_postgresql_app_password` |

Para ver las contraseñas: `ansible-vault view group_vars/servidor/vault.yml`

## Qué pidió la tarea y dónde está

| Pedido | Dónde |
|---|---|
| Apache, PHP, phpMyAdmin | roles `apache`, `php`, `phpmyadmin` |
| MariaDB configurado | rol `mariadb`: contraseña de root, base `aso_db`, usuario `aso_admin` |
| Samba con create mask | rol `samba`: usuarios `aso01` y `aso02`, carpeta `/opt/files`, mask `0740` |
| Hosts sin usuario ni contraseña | `inventory/hosts` solo tiene la IP; contraseñas cifradas en el vault |
| Más rápido | `ansible.cfg`: pipelining, conexiones SSH reutilizadas, caché de facts |
| Roles | carpeta `roles/`, un rol por servicio |
| Plantillas en Git | `vsftpd.conf.j2`, `smb.conf.j2`, `pg_hba.conf.j2` |
| PostgreSQL | rol `postgresql`: usuario, base, librería `php8-pgsql`, solo conexiones SSL |

## Si algo falla

| Mensaje | Solución |
|---|---|
| `UNREACHABLE` | Revisar la IP en `inventory/hosts` |
| `Permission denied` en `ssh-copy-id` | En el destino falta el paso de `PermitRootLogin yes` |
| `No se pudo entrar a MariaDB como root...` | El destino no está vacío: ya tenía MariaDB con otra contraseña |
| `Decryption failed` | La clave del vault está mal escrita |

| `Connection refused` | Verificar que el servicio SSH esté activo en la máquina destino. |

## Contributors

Rodrigo Mamani Rocha
Franz Gabriel Totora Huanca
