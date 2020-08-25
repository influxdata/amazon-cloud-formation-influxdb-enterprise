import * as asg from '@aws-cdk/aws-autoscaling';
import * as elbv2 from '@aws-cdk/aws-elasticloadbalancingv2';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as cdk from '@aws-cdk/core';

// import autoscaling = require('@aws-cdk/aws-autoscaling');
// import ec2 = require('@aws-cdk/aws-ec2');
// import elbv2 = require('@aws-cdk/aws-elasticloadbalancingv2');
// import cdk = require('@aws-cdk/core');

export class TestCdkStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // const queue = new sqs.Queue(this, 'TestCdkQueue', {
    //   visibilityTimeout: cdk.Duration.seconds(300)
    // });

    // const topic = new sns.Topic(this, 'TestCdkTopic');

    // topic.addSubscription(new subs.SqsSubscription(queue));

    const vpc = new ec2.Vpc(this, 'VPC');

    const dataAsg = new asg.AutoScalingGroup(this, 'ASG', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T2, ec2.InstanceSize.MICRO),
      machineImage: new ec2.AmazonLinuxImage(),
    });

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
