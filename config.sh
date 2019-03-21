#!/bin/bash

sudo cat > start-netcat-loop.sh <<EOL
#!/bin/bash

while true 
do 
    echo "UDP Server: $HOSTNAME" | nc -u -l -w 1 5683 
done
EOL

chmod a+x start-netcat-loop.sh
script=$(realpath start-netcat-loop.sh)

touch background-process.service

sudo cat > background-process.service <<EOL
[Unit]
Description=Backgroun Process
After=syslog.target network.target

[Service]
Type=simple
User=root
ExecStart=$script
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

sudo cp background-process.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo service background-process start
sudo sudo systemctl enable background-process