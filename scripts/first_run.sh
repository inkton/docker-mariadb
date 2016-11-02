DB_USER=${DB_USER:-super}
DB_PASS=${DB_PASS:-$(pwgen -s -1 16)}

pre_start_action() {
  # Echo out info to later obtain by running `docker logs container_name`
  echo "MARIADB_USER=$DB_USER"
  echo "MARIADB_PASS=$DB_PASS"
  echo "MARIADB_DATA_DIR=$DATA_DIR"

  # test if DATA_DIR has content
  if [[ ! "$(ls -A $DATA_DIR)" ]]; then
      echo "Initializing MariaDB at $DATA_DIR"
      # Copy the data that we generated within the container to the empty DATA_DIR.
      cp -R /var/lib/mysql/* $DATA_DIR
  fi

  # Ensure mysql owns the DATA_DIR
  chown -R mysql $DATA_DIR
  chown root $DATA_DIR/debian*.flag
}

post_start_action() {
  # The password for 'debian-sys-maint'@'localhost' is auto generated.
  # The database inside of DATA_DIR may not have been generated with this password.
  # So, we need to set this for our database to be portable.
  DB_MAINT_PASS=$(cat /etc/mysql/debian.cnf | grep -m 1 "password\s*=\s*"| sed 's/^password\s*=\s*//')
  mysql -u root -e \
      "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '$DB_MAINT_PASS';"

  # Create the superuser.
  mysql -u root <<-EOF
      DELETE FROM mysql.user WHERE user = '$DB_USER';
      FLUSH PRIVILEGES;
      CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
      GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;
      CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
      GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;
EOF

  rm /firstrun
}
