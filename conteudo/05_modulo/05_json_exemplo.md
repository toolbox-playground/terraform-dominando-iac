# Módulo 05 - HCL

## Exemplo JSON

```yaml
{
  "resource": {
    "aws_instance": {
      "example": {
        "ami": "ami-0c55b159cbfafe1f0",
        "instance_type": "t2.micro",
        "tags": {
          "Name": "ExampleInstance"
        }
      }
    }
  },
  "variable": {
    "region": {
      "default": "us-west-2"
    }
  },
  "output": {
    "instance_ip": {
      "value": "${aws_instance.example.public_ip}"
    }
  }
}
```
