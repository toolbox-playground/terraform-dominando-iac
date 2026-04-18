provider "aws" {
region = "us-east-1"
}

resource "aws_vpc" "legacy_vpc" {
 cidr_block="10.0.0.0/16"

tags = {
Name="LegacyVPC"
}
}

resource "aws_subnet" "subnet1" {
vpc_id=aws_vpc.legacy_vpc.id
cidr_block = "10.0.1.0/24"
availability_zone="us-east-1a"

tags = {
Name = "LegacySubnet-1"
}
}
