# Deployment guide

This file contains the instructions for manual deployment of the full infrastructure using shell scripts.

## Requirements

The host where the instructions are running requires the following tools installed:

- azure-cli
- terraform
- docker
- kubectl

If development is required, other tools are also needed:

- python
- golang
- curl (testing)

For VS Code, the following extensions are helpful: Mardownlint, Markdown all in one, Docker, Terraform, Terraform for Azure Resources, isort, Black, Python, Go.

## Permissions

For the deployment a Terraform Service Principal must be created with the following capabilities:

- Contributor role over Subscription to be able to create resources (or a more granular role)
- Be able to assign ACR Pull role to the AKS Server
  - This can be achieved by assigning Owner Role over the Subscription/Resource Group or by using a more restrictive approach (Role Based Access Control Administrator with conditions).

## Steps

1. Populate the following files with the necessary variables.
   1. `$workspaceFolderPath/src/infrastructure-deployment/env.cfg`
   2. `$workspaceFolderPath/src/infrastructure-deployment/acr/acr.tf`
   3. `$workspaceFolderPath/src/infrastructure-deployment/aks/variables.tf`

    These variables should be centralized when moving to full automation.

    Pay attention that the values correspond between files. E.g. ACR name.

2. Setup environment.

    ```bash
    workspaceFolderPath="<replace-this>"
    cd $workspaceFolderPath/src/infrastructure-deployment
    source env.cfg

    az login --use-device-code # should be replaced with technical user / (terraform) service principal
    az account set az account set --subscription $SUBSCRIPTION
    ```

3. Deploy ACR.

    _May be skipped if the ACR is already deployed._

    ```bash
    cd $workspaceFolderPath/src/infrastructure-deployment/acr
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

4. Login to ACR.

    ```bash
    az acr login -n $ACR_NAME
    ```

5. Build, tag, and push image - Service A.

    _May be skipped if the image is already present in the ACR._

    ```bash
    # Service A
    cd $workspaceFolderPath/src/apps/$SERVICE_A

    docker build -t $SERVICE_A -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_A/dockerfile .
    docker tag $SERVICE_A $ACR_NAME.azurecr.io/samples/$SERVICE_A
    docker push $ACR_NAME.azurecr.io/samples/$SERVICE_A
    ```

6. Build, tag, and push image - Service B.

    _May be skipped if the image is already present in the ACR._

    ```bash
    # Service B
    cd $workspaceFolderPath/src/apps/$SERVICE_B

    docker build -t $SERVICE_B -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_B/dockerfile .
    docker tag $SERVICE_B $ACR_NAME.azurecr.io/samples/$SERVICE_B
    docker push $ACR_NAME.azurecr.io/samples/$SERVICE_B
    ```

7. Deploy AKS.

    ```bash
    cd $workspaceFolderPath/src/infrastructure-deployment/aks
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

8. Setup AKS Cluster acces through `kubeconfig`.

    ```bash
    echo "$(terraform output kube_config)" > ../azurek8s
    sed -i '1d' ../azurek8s && sed -i '$ d' ../azurek8s # remove first line and last line
    export KUBECONFIG="$workspaceFolderPath/src/infrastructure-deployment/azurek8s"
    ```

9. Deploy NGINX Ingress Controller.

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml
    ```

10. Deploy Service A (crypto-wrapper) to AKS.

    ```bash
    cd $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_A
    kubectl apply -f ./deployment.yaml
    ```

11. Deploy Service B (simple-server) to AKS.

    ```bash
    cd $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_B
    kubectl apply -f ./deployment.yaml
    ```

12. Deploy Ingress to route traffic to Service A and Service B.

    ```bash
    cd $workspaceFolderPath/src/infrastructure-deployment/service-deployments/ingress-rules
    kubectl apply -f ./deployment.yaml
    ```
