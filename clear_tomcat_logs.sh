#!/bin/bash
# clear tomcat logs
KEEP_TIME=200
DOMAIN_HOME="/opt/server/tomcat*"
/usr/bin/find $DOMAIN_HOME/logs -mtime +$KEEP_TIME -exec rm -rf {} \; >>/tmp/clean_tomcat_logs.log
exit 0
