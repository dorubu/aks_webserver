#!/bin/bash

# This setup assumes that permissions are set in place and the following files are populated with the right values.
# $workspaceFolderPath/src/infrastructure-deployment/env.cfg
# $workspaceFolderPath/src/infrastructure-deployment/acr/acr.tf
# $workspaceFolderPath/src/infrastructure-deployment/aks/variables.tf

# Setup environment
workspaceFolderPath="<replace-this>"
source $workspaceFolderPath/src/infrastructure-deployment/env.cfg
echo "Environment variables have been setup."


# Login to Azure
az login # should be replaced with non-interactive technical user / (terraform) service principal
az account set az account set --subscription $SUBSCRIPTION
echo "Azure login was successful."
echo "Subscription: $SUBSCRIPTION."


# Deploy ACR
cd $workspaceFolderPath/src/infrastructure-deployment/acr

terraform init
terraform plan -out acr.tfplan
terraform apply acr.tfplan

echo "ACR deployment was successful."
echo "ACR: $ACR_NAME"


# ACR Login
az acr login -n $ACR_NAME
echo "ACR login was successful."


# Build, tag, and push image - Service A
cd $workspaceFolderPath/src/apps/$SERVICE_A

docker build -t $SERVICE_A -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_A/dockerfile .
docker tag $SERVICE_A $ACR_NAME.azurecr.io/samples/$SERVICE_A
docker push $ACR_NAME.azurecr.io/samples/$SERVICE_A

echo "Service A docker Image was uploaded to ACR."
echo "Service A name: $SERVICE_A."


# Build, tag, and push image - Service B
cd $workspaceFolderPath/src/apps/$SERVICE_B

docker build -t $SERVICE_B -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_B/dockerfile .
docker tag $SERVICE_B $ACR_NAME.azurecr.io/samples/$SERVICE_B
docker push $ACR_NAME.azurecr.io/samples/$SERVICE_B

echo "Service B docker Image was uploaded to ACR."
echo "Service B name: $SERVICE_B."


# Deploy AKS
cd $workspaceFolderPath/src/infrastructure-deployment/aks

terraform init
terraform plan 
terraform apply -auto-approve

# Setup kubeconfig
echo "$(terraform output kube_config)" > ../azurek8s
sed -i '1d' ../azurek8s # remove first line
sed -i '$ d' ../azurek8s # remove last line
export KUBECONFIG="$workspaceFolderPath/src/infrastructure-deployment/azurek8s"

echo "AKS deployment was successful."
echo "AKS: $AKS_NAME"


# Deploy NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml

echo "NGINX Ingress Controller deployment was successful."


# Deploy Ingress to AKS.
kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/aks-network-setup/ingress.deployment.yaml
echo "Ingress deployment to AKS was successful."


# Deploy Network Policies to AKS.
kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/aks-network-setup/network-policies.deployment.yaml
echo "network policies deployment to AKS was successful."


# Deploy Service A to AKS
kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_A/deployment.yaml
echo "Service A deployment to AKS was successful."


# Deploy Service B to AKS.
kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_B/deployment.yaml
echo "Service B deployment to AKS was successful."