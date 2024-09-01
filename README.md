# Gropius Terraform Deployment

This repository contains the Terraform configuration for deploying the Gropius system.
This deployment leverages Kubernetes as the underlying infrastructure and can be customized using several input variables.

## Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html) installed on your machine.
-   Access to a Kubernetes cluster.
-   A valid `kubeconfig` file for accessing your Kubernetes cluster.

## Input Variables

Below are the input variables used in this deployment:

| Variable           | Type   | Description                                                                            | Default Value           |
| ------------------ | ------ | -------------------------------------------------------------------------------------- | ----------------------- |
| `admin_password`   | string | The password for the admin user                                                        | `admin`                 |
| `namespace`        | string | The k8s namespace to deploy the application in                                         | `gropius`               |
| `gropius_endpoint` | string | The host URL of the Gropius frontend                                                   | `http://localhost:4200` |
| `gropius_version`  | string | The version of Gropius to deploy                                                       | `latest`                |
| `enable_ingress`   | bool   | Whether to enable ingress (only relevant if `gropius_endpoint` starts with `https://`) | `false`                 |
| `sync_github`      | bool   | Whether to sync the GitHub repositories                                                | `false`                 |
| `sync_jira`        | bool   | Whether to sync the Jira issues                                                        | `false`                 |
| `storage_class`    | string | The storage class to use for all databases (nullable)                                  | `null`                  |
| `kubeconfig`       | string | The kubeconfig file to use for `kubectl`                                               | `./kubeconfig.yaml`     |

## Deployment Steps

1. **Clone the Repository:**

    ```bash
    git clone https://github.com/ccims/gropius-tf
    cd gropius-tf
    ```

2. **Initialize Terraform:**

    Initialize the Terraform workspace by running:

    ```bash
    terraform init
    ```

3. **Customize Input Variables:**

    If you want to override any default input variables, you can do so by creating a `terraform.tfvars` file in the repository directory:

    ```hcl
    admin_password = "your_admin_password"
    gropius_endpoint = "http://your-gropius-url"
    enable_ingress = true
    sync_github = true
    sync_jira = true
    storage_class = "your_storage_class"
    kubeconfig = "/path/to/your/kubeconfig.yaml"
    ```

4. **Apply the Terraform Configuration:**

    Run the following command to deploy the Gropius system:

    ```bash
    terraform apply --var-file=terraform.tfvars
    ```

    Confirm the prompt to proceed with the deployment.

5. **Access Gropius:**

    Once the deployment is complete, you can access the Gropius frontend using the URL provided in the `gropius_endpoint` variable.
    When using the default configuration, don't forget to port-forward the Gropius frontend service to access it locally:

    ```bash
    kubectl -n gropius port-forward service/frontend 4200:80
    ```

    Then, open your browser and navigate to `http://localhost:4200`.

## Cleanup

To destroy the Gropius deployment, run:

```bash
terraform destroy
```

This will remove all resources created by this Terraform configuration.