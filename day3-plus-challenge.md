# Day 3+ Challenge — Deploy and Connect to First Azure VM

**Date:** August 12, 2025  
**Public IP:** 40.84.63.223 (now deleted)  
**Region:** eastus2  
**VM Name:** day3vm  
**Login User:** azureuser  

## What I Did
- Created a resource group in Azure CLI.
- Deployed a small Ubuntu 22.04 VM (`Standard_B1s` size).
- SSH’d into the VM and verified it was running.
- Created and read a text file inside the VM.
- (Optional) Installed nginx web server.
- Deleted all resources to avoid cost.

## Commands Used
```bash
az group create --name vmChallengeGroup --location eastus2
az vm create \
  --resource-group vmChallengeGroup \
  --name day3vm \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys
az vm show -g vmChallengeGroup -n day3vm --show-details --query publicIps -o tsv
ssh azureuser@40.84.63.223
mkdir ~/day3_test
echo "Hello from Day 3 VM" > ~/day3_test/hello.txt
cat ~/day3_test/hello.txt
sudo apt update
sudo apt install -y nginx
curl -I http://localhost
exit
az group delete --name vmChallengeGroup --yes --no-wait
