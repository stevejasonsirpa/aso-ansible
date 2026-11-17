GRUPO 12 - DESPLIEGUE CON ANSIBLE EN OPENSUSE 16


Que hace: desde una maquina MASTER instala y configura, en una maquina DESTINO vacia,
FTP, Apache + PHP + phpMyAdmin + MariaDB, Samba y PostgreSQL.


a) LINK A GITHUB


https://github.com/stevejasonsirpa/aso-ansible


b) PASOS PARA EJECUTAR


Todo como root en el MASTER.

En el DESTINO solo hace falta permitir root por SSH (una vez):

   echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/10-root.conf
   systemctl restart sshd


1. Instalar herramientas

   zypper -n install git ansible python313-passlib

2. Clonar el repositorio

   git clone https://github.com/stevejasonsirpa/aso-ansible.git
   cd aso-ansible

3. Poner la IP del destino en el archivo hosts

   nano inventory/hosts

      [servidor]
      destino ansible_host=IP_DEL_DESTINO

4. Copiar la llave SSH al destino (pide la contrasena de root del destino una vez)

   ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519     (si pregunta Overwrite, responder n)
   ssh-copy-id root@IP_DEL_DESTINO

5. Crear el archivo de contrasenas cifrado (vault)

   cp group_vars/servidor/vault.yml.ejemplo group_vars/servidor/vault.yml
   nano group_vars/servidor/vault.yml        (cambiar cada CAMBIAR por una contrasena)
   ansible-vault encrypt group_vars/servidor/vault.yml   (pide inventar una clave)

6. Ejecutar midiendo el tiempo

   La clave del vault se guarda en un archivo para que time mida solo el despliegue:

   nano ~/.vault_pass                    (escribir la clave del vault del paso 5)
   chmod 600 ~/.vault_pass
   time ansible-playbook site.yml --vault-password-file ~/.vault_pass

   Tambien se puede preguntar la clave: time ansible-playbook site.yml --ask-vault-pass

   Resultado esperado: failed=0 (unos 4 minutos).
   Si se ejecuta otra vez: changed=0 en segundos.


COMPROBAR


phpMyAdmin:  navegador -> http://IP_DEL_DESTINO/phpmyadmin   (usuario root)
FTP:         ftp IP_DEL_DESTINO                               (usuario aso01)
Samba:       smbclient //IP_DEL_DESTINO/files -U aso01
             los archivos subidos quedan con permisos -rwxr-----  (create mask 0740)
PostgreSQL:  psql "host=IP_DEL_DESTINO dbname=aso_pg user=aso_pg_admin sslmode=require"
             (sin cifrado, sslmode=disable, el servidor rechaza la conexion)

USUARIOS Y CONTRASENAS (las que se escribieron en el vault, paso 5)

   Para entrar a                       Usuario          Contrasena (variable del vault)
   phpMyAdmin / MariaDB (admin)        root             vault_mariadb_root_password
   phpMyAdmin / MariaDB (base aso_db)  aso_admin        vault_mariadb_app_password
   FTP y Samba                         aso01 o aso02    vault_samba_password
   PostgreSQL (admin)                  postgres         vault_postgresql_postgres_password
   PostgreSQL (base aso_pg)            aso_pg_admin     vault_postgresql_app_password

   Para ver las contrasenas: ansible-vault view group_vars/servidor/vault.yml


SI ALGO FALLA
-------------

UNREACHABLE                          revisar la IP en inventory/hosts
Connection refused                   en el destino: systemctl enable --now sshd
Permission denied en ssh-copy-id     en el destino falta PermitRootLogin yes
No se pudo entrar a MariaDB...       el destino no esta vacio (ya tenia MariaDB con otra clave)
Decryption failed                    la clave del vault esta mal escrita


QUE PIDIO LA TAREA Y DONDE ESTA


Apache, PHP, phpMyAdmin          roles apache, php, phpmyadmin
MariaDB configurado              rol mariadb (contrasena de root, base aso_db, usuario aso_admin)
Samba con create mask            rol samba (usuarios aso01 y aso02, carpeta /opt/files, mask 0740)
Hosts sin usuario ni contrasena  inventory/hosts solo tiene la IP; contrasenas cifradas en el vault
Mas rapido                       ansible.cfg (pipelining, conexiones SSH reutilizadas, cache)
Roles                            carpeta roles/ (un rol por servicio)
Plantillas en Git                vsftpd.conf.j2, smb.conf.j2, pg_hba.conf.j2
PostgreSQL                       rol postgresql (usuario, base, libreria php8-pgsql, solo SSL)

