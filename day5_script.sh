#!/bin/bash
# Day 5 Azure Bash Script
#Variables
RESOURCE_GROUP="StorageRG"
LOCATION="eastus2"
STORAGE_NAME="mendozastoragejoe$RANDOM"
#Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
#create storage account
az storage account create \
--name $STORAGE_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--sku Standard_LRS
# List storage accounts
az storage account list --resource-group $RESOURCE_GROUP -o table
