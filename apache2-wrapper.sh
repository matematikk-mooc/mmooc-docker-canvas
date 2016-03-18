#! /bin/bash

export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data
export APACHE_PID_FILE=/var/run/apache2.pid
export APACHE_RUN_DIR=/var/run/apache2
export APACHE_LOCK_DIR=/var/lock/apache2
export APACHE_LOG_DIR=/var/log/apache2
export LANG=C


dirs="/opt/canvas-lms/log /opt/canvas-lms/tmp/files"
chown canvasuser $dirs
chmod 0777 $dirs

/opt/canvas-lms/script/canvas_init start
exec /usr/sbin/apache2 -D FOREGROUND
