#!/bin/bash
echo "$1 $2" | ssh  -o StrictHostKeyChecking=accept-new -i /config/ssh/id_apache user@apache-server
