# AWS Cloud Formation Templates for InfluxDB Enterprise

This repository contains CloudFormation templates which can be used to deploy a
production-ready InfluxDB Enterprise cluster. These are also the source AMI and
CloudFormation templates used in [InfluxData's InfluxDB Enterprise product]()
listed on the AWS Marketplace.

![Architecture of an InfluxDB Enterprise cluster deployed through AWS Marketplace](aws-marketplace-influxdb-enterprise.png)

## Getting Started

Subscribe to the [InfluxDB Enterprise product on AWS Marketplace](). This
provides access to several AMIs which can be deployed as an InfluxDB Enterprise
cluster using AWS CloudFormation.

### Deploy using AWS Marketplace (recommended)

After subscribing, choose one of several template options available when
deploying an InfluxDB Enterprise cluster through the AWS Marketplace. The AWS
Marketplace InfluxDB Enterprise product uses templates based off the ones in
this repo.

__Billing options:__

- Default: The default templates have integrated billing through AWS
  Marketplace. InfluxDB Enterprise license costs are added to your AWS bill when
  deploying these templates.
- BYOL: The bring-your-own-license templates require an InfluxDB Enterprise
  license key obtained from and billed to InfluxData outside AWS. [Sign up for a
  free two-week trial license here](https://portal.influxdata.com/users/new).

__Network options:__

- Multi-AZ: This template deploys an InfluxDB Enterprise cluster in a new VPC
  with subnets in three different availability zones. This option is best for
  operators who want the cluster deployed in a new VPC with nodes partitioned
  among different availability zones.
- Single-AZ: This template deploys an InfluxDB Enterprise cluster in an existing
  subnet with all nodes in a single availability zone. This option is best for
  operators who want InfluxDB in an existing subnet.

Once a template is chosen, fill out the CloudFormation parameters and deploy the
template. See the [documentation]() for more information on the required
parameters.

The documentation describes how to make changes to an InfluxDB Enterprise
cluster deployed by these templates.

### Deploy using the AWS CLI

The templates in this repo can be used to deploy an InfluxDB Enterprise cluster
using the AWS CLI.

First, install and configure the AWS CLI with your account credentials.

Next run either the `deploy-multi-az.sh` and `deploy-single-az.sh` script to
call an AWS CLI command to start a cluster. The scripts are build only to deploy
BYOL templates so a license key must be passed in as an environment variable.

```sh
export LICENSE_KEY=a1b2c3d4-xxxx-xxxx-xxxx-xxxxxxxxxxxx
./deploy-multi-az.sh
```

## Building the AMIs

__Note: Images do not have to be build when subscribing to the InfluxDB
Enterprise product on the AWS Marketplace. Instead use the AMIs already included
in the CloudFormation templates.__

Building new AMIs with updated OS or InfluxDB versions is straightforward using
[Hashicorp's Packer](https://www.packer.io/docs/builders/amazon.html). Packer
templates can be found in the `packer` directory of this repo.

First, install Packer and the AWS CLI. Configure the AWS CLI with your account
credentials.

Then, switch to the `cf-templates` directory and run the following command to
build an AMI.

```sh
cd cf-templates
packer build byol-multi-az.json
```
