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

The ARM template creates a virtual network with two subnets, one for each virtual machine scale set hosting, respectively, the backend service for TCP-based requests and the backend service for UDP-based requests. Each virtual machine scale set is configured to: 
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

TCP