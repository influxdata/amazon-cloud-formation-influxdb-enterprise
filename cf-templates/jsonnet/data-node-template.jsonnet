


// function(data_node_count) {
    // local data_node(index) = if x == 0 then [] else data_node(index - 1) + [index],
    // local arr = std.range(0, data_node_count)
    // [
    //     ['DataNodeEni' + node_index]: {
    //         "Type": "AWS::EC2::NetworkInterface",
    //         "Properties": {
    //             "Description": "ENI for data node one ASG",
    //             "GroupSet": [
    //                 {
    //                     "Ref": "InfluxDBInternalSecurityGroup"
    //                 }
    //             ],
    //             "SubnetId": {
    //                 "Ref": "Subnet<subnet-index>"
    //             }
    //         }
    //     },
    //     ['DataNodeDns' + node_index]: {
    //         "Type": "AWS::Route53::RecordSet",
    //         "Properties": {
    //             "ResourceRecords": [
    //                 {
    //                     "Fn::GetAtt": [
    //                         "DataNodeEni" + node_index,
    //                         "PrimaryPrivateIpAddress"
    //                     ]
    //                 }
    //             ],
    //             "HostedZoneId": {
    //                 "Ref": "InfluxDBPrivateHostedZone"
    //             },
    //             "Name": "data-" + node_index + ".influxdb.internal",
    //             "Type": "A",
    //             "TTL": "60"
    //         }
    //     },
    //     ['DataNodeVolume' + node_index]: {
    //         "Type": "AWS::EC2::Volume",
    //         "Properties": {
    //             "AvailabilityZone": {
    //                 "Fn::GetAtt": [
    //                     "Subnet<subnet-index>",
    //                     "AvailabilityZone"
    //                 ]
    //             },
    //             "Size": {
    //                 "Ref": "DataNodeDiskSize"
    //             },
    //             "VolumeType": "io1",
    //             "Iops": {
    //                 "Ref": "DataNodeDiskIops"
    //             },
    //             "AutoEnableIO": true,
    //             "Encrypted": true
    //         },
    //         "DeletionPolicy": "Snapshot"
    //     },
    //     ['DataNodeAutoScalingGroup' + node_index]: {
    //         "Type": "AWS::AutoScaling::AutoScalingGroup",
    //         "Properties": {
    //             "VPCZoneIdentifier": [
    //                 {
    //                     "Ref": "Subnet<subnet-index>"
    //                 }
    //             ],
    //             "LaunchConfigurationName": {
    //                 "Ref": "DataNodeLaunchConfiguration"
    //             },
    //             "DesiredCapacity": "1",
    //             "MinSize": "0",
    //             "MaxSize": "1",
    //             "TargetGroupARNs": [
    //                 {
    //                     "Ref": "InfluxDBLoadBalancerTargetGroup"
    //                 }
    //             ],
    //             "Tags": [
    //                 {
    //                     "Key": "influxdb-eni",
    //                     "Value": {
    //                         "Ref": "DataNodeEni" + node_index
    //                     },
    //                     "PropagateAtLaunch": true
    //                 },
    //                 {
    //                     "Key": "influxdb-volume",
    //                     "Value": {
    //                         "Ref": "DataNodeVolume" + node_index
    //                     },
    //                     "PropagateAtLaunch": true
    //                 },
    //                 {
    //                     "Key": "influxdb-hostname",
    //                     "Value": {
    //                         "Ref": "DataNodeDns" + node_index
    //                     },
    //                     "PropagateAtLaunch": true
    //                 },
    //                 {
    //                     "Key": "Name",
    //                     "Value": "data-" + node_index,
    //                     "PropagateAtLaunch": true
    //                 }
    //             ]
    //         },
    //         "CreationPolicy": {
    //             "ResourceSignal": {
    //                 "Count": "1",
    //                 "Timeout": "PT60M"
    //             }
    //         },
    //         "UpdatePolicy": {
    //             "AutoScalingRollingUpdate": {
    //                 "MinInstancesInService": 0,
    //                 "MaxBatchSize": 1,
    //                 "PauseTime": "PT10M",
    //                 "WaitOnResourceSignals": true
    //             }
    //         }
    //     },
    // ],
    // for node_index in std.range(0, data_node_count)
// }