Para marcar a resource como tainted e forçar sua recriação, execute:

```
terraform taint aws_instance.example
```

Caso deseje reverter a marcação (por engano), execute:
```
terraform untaint aws_instance.example
```