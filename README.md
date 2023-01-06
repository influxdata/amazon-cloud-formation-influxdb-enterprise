# [NOTICE] This repo is archived.

The cooresponding AWS Marketplace offer that used these templates has been deprecated. This repo is being archived to reflect the lack of active development and support for these templates.

# InfluxDB Enterprise AWS Cloud Formation Templates

This repository contains templates to build AMIs for InfluxDB Enterprise as well as CloudFormation templates to deploy and configure an InfluxDB Enterprise cluster. These are also the source AMI and
CloudFormation templates used in [InfluxData's InfluxDB Enterprise product](https://aws.amazon.com/marketplace/pp/InfluxData-Inc-InfluxDB-Enterprise/prodview-m6excs2fnnq5c)
listed on the AWS Marketplace.

![Architecture of an InfluxDB Enterprise cluster deployed through AWS Marketplace](aws-marketplace-influxdb-enterprise.png)

## Getting Started

The assets in this repo can be used on their own or through the AWS Marketplace. The benefit of using AWS Marketplace is that the InfluxDB Enterprise license is billed through AWS. The templates in this repo can also be used directly outside the AWS Marketplace. However, these templates and images are not required to run InfluxDB Enterprise on AWS Marketplace. See the [Installation guide](https://docs.influxdata.com/enterprise_influxdb/v1.8/introduction/installation_requirements/) to learn how to install InfluxDB Enterprise without using the assests in this repo.

### AWS Marketplace

To deploy InfluxDB Enterprise through AWS Marketplace, subscribe to the InfluxDB Enterprise offer on AWS Marketplace](https://aws.amazon.com/marketplace/pp/InfluxData-Inc-InfluxDB-Enterprise/prodview-m6excs2fnnq5c). At the end of the subscription flow, you will be provided access to several AMIs for InfluxDB Enterprise and the option to deploy them as an InfluxDB Enterprise
cluster using AWS CloudFormation. When using this method, an InfluxDB Enterprise license key is not needed and the license costs for usage are automatically billed through AWS Marketplace. Please reach out to sales@influxdata.com for more details.

### Using the templates in this repo

The templates in this repo can be used to deploy an InfluxDB Enterprise cluster without using the AWS Marketplace. Note that this may not be the most flexible deployment pattern for upgrades.

#### Prerequisites

- Install [Hashicorp's Packer](https://www.packer.io/docs/builders/amazon.html) image build tool.
- Install [AWS' CLI tool](https://aws.amazon.com/cli/).
  - Configure the AWS CLI with your account credentials, e.g. `aws configure`.

#### Build the AMI images

The first step is to build AMI images to use in the Cloud Formation templates.

_Note: InfluxData does not maintain AMIs outside the AWS Marketplace at this time. Unless you feel comfortable building your own images, we recommend subscribing to the [InfluxDB Enterprise offer](https://aws.amazon.com/marketplace/pp/InfluxData-Inc-InfluxDB-Enterprise/prodview-m6excs2fnnq5c) on AWS Marketplace or [following the InfluxDB Enterprise installation guide](https://docs.influxdata.com/enterprise_influxdb/v1.8/install-and-deploy/production_installation/)._

Install [Hashicorp's Packer](https://www.packer.io/docs/builders/amazon.html) image build tool. Configure Packer with AWS credentials. Then, run the following commands to build the images:

```
cd packer
packer build influxdb.json
```

Record the AMI IDs created by Packer.

_Note: The InfluxDB Enterprise images are based on the Amazon Linux 2 AMI._

#### Deploy the Cloud Formation template

First, install and configure the AWS CLI with your account credentials.

Replace AMI IDs in the Cloud Formation template in this repo with the AMI IDs generated above or subscribe to the InfluxDB Enterprise offer on AWS Marketplace.

Next, run either the `deploy-multi-az.sh` and `deploy-single-az.sh` script to create a cluster. When using self-built AMIs, license key must be passed in as an environment variable.

```sh
export LICENSE_KEY=a1b2c3d4-xxxx-xxxx-xxxx-xxxxxxxxxxxx
./deploy-multi-az.sh
```
