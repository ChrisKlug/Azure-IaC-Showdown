# Azure Infrastructure as Code Showdown

This repo contains the source code used for my talk "Azure IaC Showdown".

It contains the completed code in one folder for each framework. Feel free to browse around and see which syntax you prefer.

## Bicep

To run the Bidep code, make sure that your Azure CLI is logged in to the correct subscription. This can be verified by running

```bash
> az account show
```

__Note:__ If you are in the wrong subscription, you can use `az account list` to see the available subscriptions, and `az account set -s <SUBSCRIPTION ID>` to set the desired subscription.

Once that has been confirmed, you can set up the environment by running

```bash
> az group create -l NorthEurope -g iac-bicep

> az deployment group create -g iac-bicep -f main.bicep -p projectName=iac-bicep
```

The first command creates a Resource Group to deploy to, and the second creates the actual resources.

To view the `websiteUrl` output, you can run

```bash
> az deployment group show -g iac-bicep -n main --query properties.outputs.websiteUrl.value -o tsv
```

To remove the environment, you can run

```bash
> az group delete -n iac-bicep
```

## Terraform

To run the Terraform code, you need to first install Terraform. You can find more information about this at https://learn.hashicorp.com/tutorials/terraform/install-cli.

Once you have Terraform installed, you need to verify that you have the Azure CLI set up properly (see Bicep section for this).

To download the required Terraform provider, you need to run

```bash
> terraform init
```

Once this has been done, you can deploy the environment by running

```bash
> terraform apply -var 'prefix=iac-tf'
```

To read the `website_url` output, you can run

```bash
> terraform output -raw website_url
```

To remove the environment, you can run

```bash
> terraform destroy
```

## Pulumi

To run the Pulumi code, you first need to install Pulumi. You can find more information about this at https://www.pulumi.com/docs/get-started/install/.

Once you have Pulumi installed, you need to verify that you have the Azure CLI set up properly (see Bicep section for this).

To run execute the Pulumi code, you just run

```bash
> pulumi up
```

However, this cammnd requires you to input a passphrase. For this project, the passprase is __Password1!__.

To view the `websiteUrl` output, you can run

```bash
> pulumi stack output websiteUrl
```

To remove the environment, you can run

```bash
> pulumi destroy
```

## Contact

That should be all the information that you need to try out the code. If you have any other questions, or need help with IaC, send me a tweet. I'm available at [@ZeroKoll](https://twitter.com/ZeroKoll).