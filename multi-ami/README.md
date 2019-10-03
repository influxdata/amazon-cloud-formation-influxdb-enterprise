# AWS Cloud Formation Templates for InfluxDB Enterprise

This repository contains CloudFormation templates which can be used to deploy a
production-ready InfluxDB Enterprise cluster.

## Prerequisites

An InfluxDB Enterprise subscription must be optained to deploy a cluster. There
are two ways to obtain a license:

1. Subscribe to [Influxdata's InfluxDB Enterprise solution on AWS
   Marketplace](placeholder).
2. Bring your own license key. [Sign up for a free two-week trial
   license](https://portal.influxdata.com/users/new).

This will affect which template should be used:

- AWS Marketplace subscribers with access to the solution AMIs should use
  templates with "billing" in the name.
  - __Note:__ These are the source templates used when an InfluxDB Enterprise
    cluster is created directly through the CloudFormation console UI after
    subscribing.
- InfluxData Portal subscribers with a license key should use templates with
  "byol" (bring your own license) in the name.

## Deployment

There are two cluster configurations to deploy a cluster in either a single
availability zone or three availability zones.



Login to an AWS account and subscribe to the [InfluxDB Enterprise solution on the AWS Marketplace]().

When signing up for the solution 

This template can be deployed from the AWS Marketplace or via the AWS CLI using
the template in this repo.

To deploy the template in this repo, make sure you have the AWS CLI installed
and configured with your account credentials. Then run the following script.

```sh
export LICENSE_KEY=a1b2c3d4-xxxx-xxxx-xxxx-xxxxxxxxxxxx
./deploy.sh
```

## Building the AMIs

These pre-built AMIs can be used with the BYOL templates (without a subscription
to the AWS Marketplace BYOL solution).

```
"Data": "ami-008f7c5091fac913b",
"Meta": "ami-093482b436bfdafe8",
"Monitor": "ami-0b0af8c2b43f4a937"
```

Otherwise, it's relatively easy to build new AMIs with [Hashicorp's
Packer](https://www.packer.io/docs/builders/amazon.html) using the templates in
the `packer` directory.

Note that the AMIs are also available on the AWS Marketplace so this is not
necessary to use the template.

Before running Packer, you will need to AWS CLI installed and configured.

Run the following command to build the image:

```sh
packer build influxdb-ami.json
```
