import * as asg from '@aws-cdk/aws-autoscaling';
import * as elbv2 from '@aws-cdk/aws-elasticloadbalancingv2';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as cdk from '@aws-cdk/core';
import * as cfn_inc from '@aws-cdk/cloudformation-include';

export class InfluxdbStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;

  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, 'VPC', {
      cidr: "10.0.0.0/16",
      natGatewaySubnets: {
        subnetName: 'Public'
      },
      subnetConfiguration: [
        {
          cidrMask: 26,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC
        },
        {
          name: 'Database',
          subnetType: ec2.SubnetType.PRIVATE
        },
    })

    const selection = vpc.selectSubnets({
      subnetType: ec2.SubnetType.PRIVATE
    });
   
    for (const subnet of selection.subnets) {
      // ...
    }

    const vpcSecurityGroup = new ec2.SecurityGroup(this, 'SecurityGroup', {
      vpc: this.vpc,
      description: 'Allow ssh access to ec2 instances',
      allowAllOutbound: true
    });

    vpcSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(22),
      'allow ssh access from the world'
    );

    const dataAsg = new asg.AutoScalingGroup(this, 'ASG', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T2, ec2.InstanceSize.MICRO),
      machineImage: new ec2.AmazonLinuxImage(),
    });

    // Remove the logical ID
    const cfnDataAsg = dataAsg.node.defaultChild as asg.CfnAutoScalingGroup;
    cfnDataAsg.overrideLogicalId("ASG");

    const lb = new elbv2.ApplicationLoadBalancer(this, 'LB', {
      vpc,
      internetFacing: true,
    })

    const listener = lb.addListener('Listener', {
      port: 80
    })

    listener.addTargets('Target', {
      port: 80,
      targets: [dataAsg],
    })

    listener.connections.allowDefaultPortFromAnyIpv4('Open to the world');

    dataAsg.scaleOnRequestCount('AModestLoad', {
      targetRequestsPerSecond: 1
    })

    // const bucket = new Bucket(this, 'MyBucket');
    // let cfnBucket = bucket.node.findChild('Resource') as CfnBucket
    // cfnBucket.addPropertyOverride("AccessControl", "LogDeliveryWrite")

    // const datattemplate = new ec2.InstanceTemplate(this, "DataNodeTemplate")
  }
}
