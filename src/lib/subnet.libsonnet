local Subnet(cidr, visibility, az, tag='') = {
  Type: 'AWS::EC2::Subnet',
  Properties: {
    VpcId: { Ref: 'VPC' },
    CidrBlock: cidr,
    AvailabilityZone: {
      'Fn::Select': [az, { Ref: 'AvailabilityZones' }],
    },
    Tags: [
      { Key: 'Name', Value: visibility + ' subnet ' + az + tag },
      { Key: 'Network', Value: visibility },
    ],
    [if visibility == 'Public' then 'MapPublicIpOnLaunch']: true,
  },
};