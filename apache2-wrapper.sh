#! /bin/bash

chown canvasuser /opt/canvas-lms/log
chmod 777 /opt/canvas-lms/log

exec /usr/sbin/apache2 -D FOREGROUND
