# AWS Cloud Formation Templates for InfluxDB Enterprise

This repository contains the source template for InfluxData's InfluxDB
Enterprise listing on the AWS Marketplace.

## Deploying the template

This template can be deployed from the AWS Marketplace or via the AWS CLI using
the template in this repo.

To deploy the template in this repo, make sure you have the AWS CLI installed
and configured with your account credentials. Then run the following script.

```sh
export LICENSE_KEY=a1b2c3d4-xxxx-xxxx-xxxx-xxxxxxxxxxxx
./deploy.sh
```

## Building the AMI

[Hashicorp's Packer](https://www.packer.io/docs/builders/amazon.html) is
used to build the underlying AMI used by the template.

Note that the AMI is available on the AWS Marketplace so this is not necessary
to use the template.

Before running Packer, you will need to AWS CLI installed and configured.

Run the following command to build the image:

```sh
packer build influxdb-ami.json
```
