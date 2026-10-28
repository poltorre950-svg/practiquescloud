# Ejercicio 1: Primeras instancias EC2 con Terraform

Dos instancias `t3.micro` con Amazon Linux 2023 en `us-east-1`, desplegadas en la VPC por defecto con el recurso `aws_instance` y `count`.

![Topología](assets/topologia.png)

## Recursos

| Recurso | Nombre | Configuración |
|---------|--------|---------------|
| `aws_instance.web[0]` | `Instancia-1` | `t3.micro`, `ami-04b938437b69a2c9c` |
| `aws_instance.web[1]` | `Instancia-2` | `t3.micro`, `ami-04b938437b69a2c9c` |

No se crea red propia: se usa la VPC por defecto de AWS (subred, Security Group e IP pública automáticos).

## Código

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  count = 2

  ami           = "ami-04b938437b69a2c9c" # Amazon Linux 2023 (us-east-1)
  instance_type = "t3.micro"

  tags = {
    Name = "Instancia-${count.index + 1}"
  }
}
```

## Pasos

```bash
terraform init
terraform plan     # Plan: 2 to add
terraform apply
terraform destroy  # al terminar, para evitar costes
```

Verificación: en **EC2 → Instances** (`us-east-1`) deben aparecer `Instancia-1` e `Instancia-2` en estado `running`.

> No se define clave SSH ni regla para el puerto 22, por lo que las instancias no admiten conexión remota tal cual.
