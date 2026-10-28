# Ejercicio 2: VPC, subredes y EC2

VPC `10.0.0.0/16` en `us-east-1` con tres subredes en `us-east-1a` y seis instancias `t3.micro` (Amazon Linux 2023) repartidas dos por subred.

## Topología

| Subred | CIDR | Direcciones útiles | Instancias |
|--------|------|--------------------|------------|
| `subred-a` | `10.0.32.0/25` | 123 | `instancia-1`, `instancia-4` |
| `subred-b` | `10.0.30.0/23` | 507 | `instancia-2`, `instancia-5` |
| `subred-c` | `10.0.33.0/28` | 11 | `instancia-3`, `instancia-6` |

Los tres rangos no se solapan y las subredes llevan etiqueta `Name` para identificarlas en la consola.

![Topología](assets/topologia.png)

![Instancias EC2](assets/ec2_instances.png)

![Subnets VPC](assets/vpc_subnets.png)

## Recursos

- 1 VPC (`aws_vpc.main`).
- 3 subredes (`aws_subnet.a`, `b`, `c`).
- 6 instancias (`aws_instance.web["instancia-1"]` … `["instancia-6"]`), creadas con `for_each`.

## Código

```hcl
resource "aws_instance" "web" {
  for_each = {
    "instancia-1" = aws_subnet.a
    "instancia-2" = aws_subnet.b
    "instancia-3" = aws_subnet.c
    "instancia-4" = aws_subnet.a
    "instancia-5" = aws_subnet.b
    "instancia-6" = aws_subnet.c
  }

  ami           = "ami-04b938437b69a2c9c" # Amazon Linux 2023 (us-east-1)
  instance_type = "t3.micro"
  subnet_id     = each.value.id

  tags = {
    Name = each.key
  }
}
```

## Pasos

```bash
terraform init
terraform plan     # Plan: 10 to add (1 VPC + 3 subredes + 6 instancias)
terraform apply
terraform destroy  # al terminar, para evitar costes
```

Verificación: en **VPC → Your VPCs** debe aparecer `10.0.0.0/16`, y en **EC2 → Instances** las seis instancias en estado `running`.

> La VPC no tiene Internet Gateway, rutas ni IPs públicas: las instancias no tienen salida a internet ni acceso SSH. Para habilitarlo haría falta IGW, tabla de rutas, un Security Group con el puerto 22 y una clave.
