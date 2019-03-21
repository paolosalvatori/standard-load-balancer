#!/bin/bash
nohup sh -c 'while true; do echo "UDP Server: $HOSTNAME" | nc -u -l -w 1 5683; done;' >> nohup.out 2>&1 &