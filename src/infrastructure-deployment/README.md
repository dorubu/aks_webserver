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
    source $workspaceFolderPath/src/infrastructure-deployment/env.cfg

    az login --use-device-code # should be replaced with technical user / (terraform) service principal
    az account set az account set --subscription $SUBSCRIPTION
    ```

3. Deploy ACR.

    _May be skipped if the ACR is already deployed._

    ```bash
    cd $workspaceFolderPath/src/infrastructure-deployment/acr
    terraform init
    terraform plan -out acr.tfplan
    terraform apply acr.tfplan
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
    terraform plan -out main.tfplan
    terraform apply main.tfplan
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

10. Deploy Ingress to AKS.

    ```bash
    kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/aks-network-setup/ingress.deployment.yaml
    ```

11. Deploy Network Policies to AKS.

    - Route traffic to Service A and Service B through an NGINX Ingress Controller
    - Deny all Ingress/Egress traffic to pods
    - Allow traffic from Service A to internet

    ```bash
    kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/aks-network-setup/network-policies.deployment.yaml
    ```

12. Deploy Service A (crypto-wrapper) to AKS.

    ```bash
    kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_A/deployment.yaml
    ```

13. Deploy Service B (simple-server) to AKS.

    ```bash
    kubectl apply -f $workspaceFolderPath/src/infrastructure-deployment/service-deployments/$SERVICE_B/deployment.yaml
    ```

## Testing

### Functional requirements

The full deployment must cover the following capabilities:

1. curl service_url/crypto-wrapper/bitcoin_price
2. curl service_url/crypto-wrapper/bitcoin_average
3. curl service_url/simple-server

This can be tested using any type of web client (browser, curl, etc.).

### Cluster security

Traffic between Pods and from Service B to the internet must be disabled, which can be verified by running:

```bash
pod_b_name=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep -m1 ^$SERVICE_B)
service_a_internal_ip=$(kubectl get service/$SERVICE_A -o jsonpath='{.spec.clusterIP}')
echo $service_a_internal_ip

kubectl exec -it $pod_a_name -- /bin/bash

# Run inside the pod
target_ip="<replace with service_a_internal_ip>"
# try to connect to Service A
curl target_ip/bitcoin_average # fail
# try to connect to Internet
curl google.com # fail
```

Same thing can be done to check connectivity from Service A to Service B.

- `curl` must be installed on Service A Pod.
- To connect to Service B one must run: `curl target_ip`.
- `curl google.com` is successful.
