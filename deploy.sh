#!/bin/bash

# Variables
resourceGroup="SkynetResourceGroup"
location="westeurope"
subscriptionId=$(az account show --query id --output tsv)
template="azuredeploy.json"
parameters="azuredeploy.parameters.json"

# check if the resource group already exists
echo "Checking if ["$resourceGroup"] resource group actually exists in the ["$subscriptionId"] subscription..."

az group show --name $resourceGroup &> /dev/null

if [[ $? != 0 ]]; then
	echo "No ["$resourceGroup"] resource group actually exists in the ["$subscriptionId"] subscription"
    echo "Creating ["$resourceGroup"] resource group in the ["$subscriptionId"] subscription..."
    
    # create the resource group
    az group create --name $resourceGroup --location $location 1> /dev/null
        
    if [[ $? == 0 ]]; then
        echo "["$resourceGroup"] resource group successfully created in the ["$subscriptionId"] subscription"
    else
        echo "Failed to create ["$resourceGroup"] resource group in the ["$subscriptionId"] subscription"
        exit
    fi
else
	echo "["$resourceGroup"] resource group already exists in the ["$subscriptionId"] subscription"
    
    # Check if a load balancer exists in the resource group
    loadBalancer=$(az network lb list --resource-group $resourceGroup --query [0].name --output tsv)

    if [[ -z $loadBalancer ]]; then
        echo "No load balancer exists in the ["$resourceGroup"] resource group"
    else
        echo "["$loadBalancer]" load balancer already exists in the ["$resourceGroup"] resource group"

        # If the load balancer already exists, retrieve its Inbound NAT Pool Id 
        echo "Retrieving Inbound NAT Pool Id for the ["$loadBalancer"] load balancer"]
        loadBalancerInboundNatPoolsIds=$(az network lb list --resource-group $resourceGroup --query [].frontendIpConfigurations[0].inboundNatPools[].id --output tsv)

        if [[ ${#loadBalancerInboundNatPoolsIds[@]} == 0 ]]; then
            echo "["$loadBalancer"] load balancer does not contain any Inbound NAT Pool"
        else
            echo "["$loadBalancer"] load balancer contains one or more Inbound NAT Pools:"
            
            for id in ${loadBalancerInboundNatPoolsIds[@]}
            do
                echo " * ["$id"]"
            done

            # List existing virtual machine scale sets in the resource group
            vmssArray=$(az vmss list --resource-group $resourceGroup --query [].name --output tsv)
            for vmss in ${vmssArray[@]}
            do
                inboundNatPoolsId=$(az vmss show --name $vmss --resource-group $resourceGroup --query 'virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].loadBalancerInboundNatPools[0].id' --output tsv)

                if [[ -n $inboundNatPoolsId ]]; then
                    ok=0
                    
                    for id in ${loadBalancerInboundNatPoolsIds[@]}
                    do
                        if [[ $id == $inboundNatPoolsId ]]; then
                            ok=1
                            break
                        fi
                    done

                    if [[ $ok == 1 ]]; then
                        echo "["$vmss"] virtual machine scale set is already part of the Inbound NAT Pool ["$inboundNatPoolsId"] of the ["$loadBalancer"] load balancer"
                        echo "Removing Inbound NAT Pool reference from ["$vmss"] virtual machine scale set..."
                         az vmss update --name $vmss \
                         --resource-group $resourceGroup \
                         --remove virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].loadBalancerInboundNatPools 1> /dev/null
                         echo "Inbound NAT Pool reference successfully removed from ["$vmss"] virtual machine scale set..."
                    else
                        echo "["$vmss"] virtual machine scale set is already part of the Inbound NAT Pool ["$inboundNatPoolsId"] of a load balancer other than ["$loadBalancer"]"
                    fi
                else
                    echo "["$vmss"] virtual machine scale set is not part of any Inbound NAT Pool"
                fi
            done
        fi
    fi
fi

# validate template
echo "Validating ["$template"] ARM template..."
az group deployment validate \
--resource-group $resourceGroup \
--template-file $template \
--parameters $parameters 1> /dev/null

if [[ $? == 0 ]]; then
    echo "["$template"] ARM template successfully validated"
else
    echo "Failed to validate the ["$template"] ARM template"
    exit
fi

# deploy template
echo "Deploying ["$template"] ARM template..."
az group deployment create \
--resource-group $resourceGroup \
--template-file $template \
--parameters $parameters 1> /dev/null

if [[ $? == 0 ]]; then
    echo "["$template"] ARM template successfully provisioned"
else
    echo "Failed to provision the ["$template"] ARM template"
    exit
fi