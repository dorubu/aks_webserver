# Improvements

1. Development
   1. Commit code more iteratively when you confirm something works.
   2. Create a virtual environment for Python/Go development.
   3. Automate tools/extension installation.
   4. Coding
      1. Add extensions for Code quality: isort, Black, Flake8.
   5. Python refreshes the page every 5 seconds.
2. Automation
   1. Add Git Actions / Azure DevOps Pipelines
   2. Add trigger on repository update
   3. Create a Docker image for the host (agent) running this deployment.
   4. Separate full deployment in steps:
      1. ACR deployment
      2. Image create, tag, push
      3. AKS deployment
      4. Services deployment
   5. Clean-up files after deployment: `tfplan`, `kubeconfig`, etc.
   6. Understand the use-case. How does this need to be provided?
      1. Handle terraform race-conditions.
3. IaC quality and Azure resources standards
   1. Use central variables for all files. E.g. ACR_NAME.
   2. Use variables for location, stage, and application name.
      1. Use proper, closer location.
   3. Automate resource names creation.
      1. And add randomization if necessary.
   4. Use tagging.
4. Reliability
   1. Add System Tests add the end of the deployment: `curl` the services.
   2. Add IaC code static analyzer.
   3. Add Monitoring to AKS and Internal Services:
      1. Monitoring tools: Prometheus, App/Container Insights, etc.
      2. Visualization: Azure Monitor, Grafana.
5. Security
   1. Setup was done by using a User Identity - must move to Service Principal login.
      1. Reduced privileges.
      2. Non-interactive logins.
      3. Integration with Azure DevOps / Github Actions / others.
      4. Need to assign proper role assignments to the Service Principal:
         1. ACR Login
   2. AKS Cluster has default configuration from Azure standpoint.
      1. This requires investigation and possible improvements.
      2. For example, before applying Network policies, all Pods had bi-directional access to internet.
      3. Cluster User is able to SSH into pods.
         1. This requires investigation and possible improvements.
         2. At least block SSH traffic and deploy Jump Pod.
6. Others
   1. Pricing/deployment/time might be useful.
      1. For testing, less then 2$ were used.
   2. Setup
      1. Set SSH Key for connecting to Development VM.
      2. Permanently add Github Access SSH Key to SSH Agent.
