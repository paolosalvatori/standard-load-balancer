---
services: azure-resource-manager, virtual-machine-scale-sets, load-balancer, azure-monitor, virtual-network
author: paolosalvatori
---

# Standard Load Balancer with multiple Backend Pools #
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpaolosalvatori%2Fstandard-load-balancer%2Fmaster%2Fazuredeploy.json" rel="nofollow">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png" style="max-width:100%;">
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fpaolosalvatori%2Fstandard-load-balancer%2Fmaster%2Fazuredeploy.json" rel="nofollow">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png" style="max-width:100%;">
</a>
<br>
This template deploys a Standard Load Balancer with multiple Backend Pools and use Azure Log Analytics to monitor the virtual machine scale sets used to handle the inbound traffic.

# Scenario #
Imagine an IoT scenario where a single global load balancer is used to handle the traffic produced by thousands of devices that communicate with the cloud via a range of heterongeneous transport protocols which include HTTP/S, MQTT and CoAP. Some of these protocols, such as HTTP/S and MQTT, are TCP based, while others like CoAP are based on UDP transport protocols.

In our scenario, the load balancer is used to dispatch: 
- TCP-based requests (HTTP and MQTT) to a dedicated backend service hosted by a virtual machine scale set
- UDP-based requests (CoAP) to a dedicated backend service hosted by another virtual machine scale set.

Virtual machines in both virtual machine scale sets use Linux Ubuntu as OS, but you can eventually indicate another distro in the parameters file.

Log Analytics is used to monitor the health and performance of the virtual machines.

# Network Topology #
The following picture shows the network topology obtained using the **Topology** tool of **Azure Network Watcher**. For more information, see [View the topology of an Azure virtual network](https://docs.microsoft.com/en-us/azure/network-watcher/view-network-topology).
<br/>
<br/>
![Topology](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/topology.png)
<br/>

## Standard Load Balancer ##
The ARM template deploys a Standard Load Balancer with  a single frontend IP configuration and 3 backend pools:

- The first backend pool is used to handle TCP trafficusing load balancing rules on the following ports:
    - HTTP traffic on TCP port 80
    - HTTPS traffic on TCP port 443
    - MQTT traffic on TCP port 1883 
    - MQTT over SSL on TCP port 8883 
- The second backend pool is used to handle UDP traffic using load balancing rules on the following ports:
    - CoAP traffic on port 5683
    - CoAP traffic over SSL on port 5684
- The third backend pool includes all the virtual machines from the two previous backend pools and defines an outbound rule to provide them with outbound connectivity on TCP and UDP transport protocols. Outbound rules make it simple to configure public [Standard Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-standard-overview)'s outbound network address translation. For more information, see [Outbound Connections in Azure](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections) and [Load Balancer Oubound Rules](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-rules-overview)

Please note the following:
- Standard Load Balancer does not support more than one outbound rules that use the same frontend IP configuration and the same transport protocol.
- If an outbound rule is defined for a <frontend IP configuration, transport protocol> tuple, all the load balancing rules that use the same frontend IP configuration and transport protocol, need to have the disableOutboundSNAT property set to true.
- When the Standard Load Balancer uses a single frontend IP configuration and multiple backend pools BP1..BPn that need to open outbound connections to the internet, you can create an additional backend pool BPn+1, include in BPn+1  all the VMs from all the backend pools that need to access the internet in it, and define the outbound rule on the BPn+1 backend pool.

The following picture shows the frontend IP configuration of the standard load balancer.

![Topology](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/frontendIPConfiguration.png)
<br/>

The following picture shows the backend pools of the standard load balancer.

![Topology](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/backendPools.png)
<br/>


The following picture shows the load balancing rules created by the ARM template.

![Topology](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/loadBalancingRules.png)
<br/>

The following picture shows the inbound nat rules created by the ARM template.

![Topology](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/inboundNatRules.png)
<br/>

## Virtual Network ##

The ARM template creates a virtual network with two subnets, one for each virtual machine scale set hosting, respectively, the backend service for TCP-based requests and the backend service for UDP-based requests. 

The following picture shows the virtual machines distributed across two subnets in the virtual network:

![Virtual Network](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/vnet.png)

## Network Security Groups ##
The ARM template deploys two [network security groups](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview). Security rules are used to allow or deny inbound network traffic to, or outbound network traffic from the virtual machines in the two virtual machines scale sets.

The following picture shows the inbound and outbound rules of the network security group associated with the **TcpVmss** virtual machine scale set:

![Virtual Network](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/tcpnsg.png)

The following picture shows the inbound and outbound rules of the network security group associated with the **UdpVmss** virtual machine scale set:

![Virtual Network](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/udpnsg.png)


## Virtual Machine Scale Sets ##
The ARM template creates two virtual machine scale sets, one for handling TCP-based communications (HTTP/S and MQTT), and one for handling UDP-based requests (CoAP). 

The following picture obtained using [Azure Monitor for VMs](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/vminsights-overview) shows the virtual machines in the two virtual machine scale sets:

![Virtual Network](https://raw.githubusercontent.com/paolosalvatori/standard-load-balancer/master/images/vmss.png)

Each virtual machine scale set is configured to: 
- use Linux OS
- use accelerated networking
- be placed in a dedicated subnet of the same VNET
- be zone-redundant (zone 1 2 3)
- send data to Log Analytics
- autoscaling (CPU)
- use managed disks
- use an attached data disk
- use a custom script for VM initialization (see below)

Virtual machine scale sets are configured to use the following virtual machine extensions:
- [OmsAgentForLinux](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/oms-linux): Azure Monitor logs provides monitoring, alerting, and alert remediation capabilities across cloud and on-premises assets. The extension for Linux virtual machines installs the Log Analytics agent on Azure virtual machines, and enrolls virtual machines into an existing Log Analytics workspace. 
- [DependencyAgentLinux](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/service-map-configure): In addition to the Log Analytics agent for Linux, Linux agents require the Microsoft Dependency Agent to collect and send diagnostics data to Log Analytics Solutions such as [Service Map](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/service-map).
- [CustomScript](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux): the Azure Custom Script Extension for Linux virtual machines is used to run scripts at provisioning time on Linux virtual machines.

The Azure Custom Script Extension is used to run a bash script on the virtual machines of both virtual machine scale sets.

The following bash script is used to install NGINX on the Linux virtual machines in the **TcpVmss** virtual machine scale set:

```bash
#!/bin/bash

sudo apt-get update -y 
sudo apt-get upgrade -y
sudo apt-get install -y nginx
echo "TCP Server: $HOSTNAME" | sudo tee -a /var/www/html/index.html
```

The following bash script is used to initialize the Linux virtual machines in the **TcpVmss** virtual machine scale set. The script creates a custom service that uses netcat command to handle UDP requests on port 5683. Please note that if you have a script that will cause a reboot, then install applications and run scripts etc. You should schedule the reboot using a Cron job, or using tools such as DSC, or Chef, Puppet extensions. The CustomScript extension will only run a script once, if you want to run a script on every boot, then you can use [cloud-init image](https://docs.microsoft.com/azure/virtual-machines/linux/using-cloud-init) and use a [Scripts Per Boot](https://cloudinit.readthedocs.io/en/latest/topics/modules.html#scripts-per-boot) module. Alternatively, you can use the script to create a Systemd service unit. If you want to schedule when a script will run, you should use the extension to create a Cron job.

```bash
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
```

## Log Analytics ##
The ARM template deploys and configures a Log Analytics workspace that can be used to monitor the health and performance of the entire infrastructure and in particular of the Linux virtual machines in both virtual machines scale sets.

Log Analytics workspace is configured to use the following solutions:

- [Azure Monitor for VMs](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/vminsights-overview): Azure Monitor for VMs can be used to monitor Linux and Windows Azure virtual machines (VM) and virtual machine scale sets at scale. It analyzes the performance and health of your Windows and Linux VMs, and monitors their processes and dependencies on other resources and external processes.
- [Service Map](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/service-map): Service Map automatically discovers application components on Windows and Linux systems and maps the communication between services. With Service Map, you can view your servers in the way that you think of them: as interconnected systems that deliver critical services. Service Map shows connections between servers, processes, inbound and outbound connection latency, and ports across any TCP-connected architecture, with no configuration required other than the installation of an agent.

In addition, Log Analytics worspace is configured to retrieve syslog events and metrics (CPU, Memory, Network) from Linux virtual machines:

## Test ##
Once deployed the infrastructure, you can use the following commands to test both TCP and UDP connectivity.

```bash
#!/bin/bash
publicIp=<load-balancer-public-ip>

# Test TCP connectivity
curl $publicIp

# Test UDP connectivity
echo 'Hello' | nc -u -w 1 $publicIp 5683
```

Note that TCP requests are handled by virtual machines in the **TcpVmss** virtual machine scale set, while UDP requests are handled by virtual machines in the **UdpVmss** virtual machine scale set.