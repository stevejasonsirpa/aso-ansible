# ASO - Despliegue de servicios con Ansible

Roles de Ansible para desplegar de forma remota servicios en **openSUSE 16.0**, materia
*Aplicación de Sistemas Operativos* (Ing. Grover Cussi).

## Roles

| Rol | Qué hace | Plantilla |
|---|---|---|
| `vsftpd` | Servidor FTP con usuarios enjaulados (`chroot`), log de transferencias y puertos pasivos | `vsftpd.conf.j2` |
| `apache` | Apache 2, habilitado y con HTTP abierto en el firewall | |
| `php` | PHP 8 y su módulo para Apache | |
| `phpmyadmin` | phpMyAdmin publicado en `/phpmyadmin` | `phpMyAdmin.conf` |
| `mariadb` | Contraseña de root, sin usuarios anónimos, base `aso_db` y usuario `aso_admin` | |
| `samba` | Grupo, usuarios del sistema y de Samba, directorio `/opt/files` y recurso `[files]` con `create mask 0740` | `smb.conf.j2` |
| `postgresql` | PostgreSQL, librería `php8-pgsql`, contraseña de `postgres`, base `aso_pg`, usuario `aso_pg_admin` y conexión remota solo cifrada (SSL + scram-sha-256) | `pg_hba.conf.j2` |

## Credenciales

El inventario no tiene usuarios ni contraseñas: Ansible entra al destino con la llave SSH del
nodo master, y las contraseñas de los servicios van cifradas con `ansible-vault` en
`group_vars/servidor/vault.yml`, que **no se sube al repositorio**. Para crearlo:

```bash
cp group_vars/servidor/vault.yml.ejemplo group_vars/servidor/vault.yml
ansible-vault encrypt group_vars/servidor/vault.yml
EDITOR=nano ansible-vault edit group_vars/servidor/vault.yml
```

## Tiempo de respuesta

`ansible.cfg` activa *pipelining*, conexiones SSH persistentes (`ControlPersist`), caché de facts,
`gather_subset = min` y `profile_tasks` para medir cada tarea. Una segunda ejecución sin cambios
termina en segundos con `changed=0`.

## Uso

```bash
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --ask-vault-pass --tags postgresql
ansible-playbook site.yml --ask-vault-pass --tags lamp
```

Requisitos en el nodo master: `ansible`, `python313-passlib` y la llave SSH del master autorizada
en el destino (`ssh-copy-id root@<destino>`).
