local Subnet = import './lib/subnet.libsonnet';

local subnetName(visibility, az, tag='') =
  visibility + 'Subnet' + az + tag;
{
  Resources:
    {
      // Private subnets
      local name = subnetName('Private', az, tag),
      [name]: Subnet({ Ref: name + 'CIDR' }, 'Private', az, tag)
      for az in std.range(1, 4) for tag in ['A', 'B']
    } + {
      // Public subnets
      local name = subnetName('Public', az),
      [name]: Subnet({ Ref: name + 'CIDR' }, 'Public', az)
      for az in std.range(1, 4)
    },
}