---
services: azure-resource-manager, virtual-machine-scale-sets, load-balancer, azure-monitor, virtual-network
platforms: dotnet
author: paolosalvatori
---

# Standard Load Balancer with multiple Backend Pools #
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpaolosalvatori%2Fstandard-load-balancer%2Fmaster%2Fazuredeploy.json" rel="nofollow">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png" style="max-width:100%;">
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fpaolosalvatori%2Fstandard-load-balancer%2Fmaster%2Fazuredeploy.json" rel="nofollow">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png" style="max-width:100%;">
</a>
This template deploys a Standard Load Balancer with two Backend Pools, one for TCP load balancing rules, and one for Udpload balancing rules.