#!/usr/bin/env node
import * as cdk from '@aws-cdk/core';
import { InfluxdbStack } from '../lib/influxdb-stack';

const app = new cdk.App();
new InfluxdbStack(app, 'InfluxdbStack');
