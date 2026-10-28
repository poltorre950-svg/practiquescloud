# Ejercicio 2: Disseny i Desplegament de VPC, Subxarxes i EC2

Despliegue de una VPC con 3 subredes y 6 instancias EC2 (`t3.micro`, Amazon Linux 2023) en la región `us-east-1`, zona `us-east-1a`.

## Objetivo

Diseñar desde cero una **VPC propia** (no la VPC por defecto), dividirla en subredes con máscaras distintas y desplegar varias instancias EC2 de forma declarativa usando `for_each`, practicando el direccionamiento CIDR y la relación entre subredes e instancias.

## Direccionamiento IP y topología

| Recurso | CIDR / Tipo | Direcciones | Utilizables | Zona |
|---------|-------------|-------------|-------------|------|
| VPC | `10.0.0.0/16` | 65.536 | — | us-east-1 |
| Subnet A | `10.0.32.0/25` | 128 | 123 | us-east-1a |
| Subnet B | `10.0.30.0/23` | 512 | 507 | us-east-1a |
| Subnet C | `10.0.33.0/28` | 16 | 11 | us-east-1a |

> AWS reserva **5 direcciones IP en cada subred** (red, router, DNS, futuras y broadcast), por eso las utilizables son 5 menos que el total.

Los tres rangos son disjuntos y caben dentro de la VPC:

```
VPC 10.0.0.0/16
├── Subnet B 10.0.30.0/23   → 10.0.30.0  – 10.0.31.255
├── Subnet A 10.0.32.0/25   → 10.0.32.0  – 10.0.32.127
└── Subnet C 10.0.33.0/28   → 10.0.33.0  – 10.0.33.15
```

Las tres subredes se declaran en **`us-east-1a`**. Repartir subredes en la misma zona simplifica la práctica, aunque en un diseño real se distribuirían entre varias zonas para alta disponibilidad.

Topología general:

![Topología](assets/topologia.png)

VPC y subredes:

![VPC y Subredes](assets/vpc_subnets.png)

Instancias EC2:

![Instancias EC2](assets/ec2_instances.png)

## Recursos desplegados

- 1 VPC `10.0.0.0/16`.
- 3 subredes en `us-east-1a` con los CIDR indicados.
- 6 instancias EC2 `t3.micro` (2 por subred): `instancia-1` a `instancia-6`.
- 1 AMI de Amazon Linux 2023 obtenida dinámicamente con un *data source* (la más reciente de la cuenta `amazon`).

| Instancia | Subred | CIDR de la subred | Dirección Terraform |
|-----------|--------|-------------------|---------------------|
| `instancia-1` | A | `10.0.32.0/25` | `aws_instance.web["instancia-1"]` |
| `instancia-2` | B | `10.0.30.0/23` | `aws_instance.web["instancia-2"]` |
| `instancia-3` | C | `10.0.33.0/28` | `aws_instance.web["instancia-3"]` |
| `instancia-4` | A | `10.0.32.0/25` | `aws_instance.web["instancia-4"]` |
| `instancia-5` | B | `10.0.30.0/23` | `aws_instance.web["instancia-5"]` |
| `instancia-6` | C | `10.0.33.0/28` | `aws_instance.web["instancia-6"]` |

## Estructura

```text
pt1-4-ex2/
├── assets/
│   ├── topologia.png
│   ├── vpc_subnets.png
│   └── ec2_instances.png
├── main.tf                 # VPC, subredes e instancias
├── README.md
├── .terraform.lock.hcl     # versiones exactas del proveedor (se versiona)
├── .terraform/             # proveedor descargado (ignorado por git)
└── terraform.tfstate       # estado local (ignorado por git)
```

## Configuración (`main.tf`)

### AMI dinámica

```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

Se selecciona la AMI **más reciente** de Amazon Linux 2023 para `x86_64`. El ID concreto queda fijado en el estado al aplicar, de modo que las instancias no cambian en planes posteriores.

### VPC y subredes

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/25"
  availability_zone = "us-east-1a"
}
# ... subnets "b" (10.0.30.0/23) y "c" (10.0.33.0/28)
```

### Instancias con `for_each`

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

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id     = each.value.id

  tags = {
    Name = each.key
  }
}
```

- **`for_each`** recorre un mapa: la clave es el nombre de la instancia y el valor, la subred donde se despliega. A diferencia de `count`, permite direcciones estables (`aws_instance.web["instancia-3"]`) y añadir o quitar instancias sin recrear el resto.
- **`each.value.id`** es el ID de la subred ya creada; Terraform infiere la dependencia y crea primero la VPC y las subredes.
- **`tags.Name = each.key`** asigna el nombre definido en el mapa.

## Red y conectividad

La VPC **no incluye Internet Gateway, tabla de rutas propia, NAT ni IPs públicas**, y las instancias usan el Security Group por defecto de la VPC. Consecuencias:

- Las instancias **no tienen salida a internet** ni se puede acceder a ellas por SSH desde fuera.
- Su conectividad es **solo interna** entre instancias de la misma VPC (según reglas del Security Group por defecto).
- Esto es intencionado: el ejercicio evalúa el diseño de la VPC y las subredes, no la exposición a internet.

Para habilitar SSH habría que añadir como mínimo: un `aws_internet_gateway`, una `aws_route_table` con ruta `0.0.0.0/0`, asociarla a las subredes, un `aws_security_group` con el puerto 22 y una clave (`aws_key_pair`), además de IP pública o un `aws_eip`.

## Requisitos

- Terraform **1.5 o superior** (probado con 1.16).
- Credenciales de AWS con permisos sobre EC2 y VPC (en AWS Academy, las de la sesión del laboratorio).
- Conexión a internet para el primer `init` y para consultar la AMI.

## Procedimiento

1. **Inicializar Terraform.**

   ```bash
   cd pt1-4-ex2
   terraform init
   ```

2. **Formatear y validar (opcional, recomendado).**

   ```bash
   terraform fmt -check
   terraform validate
   ```

3. **Revisar el plan.** Deben aparecer **10 recursos**: 1 VPC + 3 subredes + 6 instancias.

   ```bash
   terraform plan
   # Plan: 10 to add, 0 to change, 0 to destroy.
   ```

4. **Crear la infraestructura.**

   ```bash
   terraform apply
   # Apply complete! Resources: 10 added, 0 changed, 0 destroyed.
   ```

5. **Verificar.** En la consola de AWS: **VPC → Your VPCs** debe mostrar la VPC `10.0.0.0/16`, y **EC2 → Instances** las seis instancias `instancia-1` … `instancia-6` en estado `running`.

   ```bash
   terraform state list
   terraform state show 'aws_instance.web["instancia-1"]' | grep -E 'id|private_ip|instance_state'
   ```

6. **Destruir los recursos.**

   ```bash
   terraform destroy
   ```

## Verificación

| Comprobación | Comando / lugar |
|--------------|-----------------|
| Recursos gestionados | `terraform state list` (10 recursos) |
| Instancias en ejecución | `terraform state show 'aws_instance.web["instancia-1"]'` |
| VPC y subredes | Consola AWS → VPC |
| Reparto por subred | `terraform state show 'aws_subnet.a'` y comparar con `subnet_id` de cada instancia |

Ejemplo para listar las IPs privadas de las seis instancias:

```bash
terraform state list | grep aws_instance
```

## Costes

- 6 × `t3.micro` en `us-east-1` (más 6 volúmenes EBS de 8 GiB por defecto).
- La capa gratuita cubre 750 horas al mes de **una** instancia `t3.micro`; seis instancias superan ese límite y generan coste.
- La VPC y las subredes no tienen coste por sí mismas.
- Ejecuta `terraform destroy` al terminar la práctica.

## Problemas comunes

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `InvalidSubnet.Conflict` / CIDR solapado | Se modificó un CIDR y pisa a otro | Revisar que los rangos no se solapen (p. ej., `10.0.32.0/23` invadiría la subred A) |
| `InsufficientFreeAddressesInSubnet` | Subred demasiado pequeña (`/28` = 11 IPs útiles) | Usar una máscara mayor |
| `ExpiredToken` | Credenciales de AWS Academy caducadas | Volver a copiar las credenciales |
| `VcpuLimitExceeded` | Límite de vCPU de la cuenta | Solicitar cuota o reducir instancias |
| La AMI cambia entre planes | Se usó una AMI fija distinta o se recreó el *data source* | Es normal: `most_recent` se resuelve al aplicar |
| Sin acceso SSH a las instancias | No hay IGW, ruta, clave ni regla 22 | Ver sección **Red y conectividad** |

## Limpieza

```bash
terraform destroy
# Destroy complete! Resources: 10 destroyed.
```

Comprueba después en la consola que no quedan instancias `running` ni la VPC `10.0.0.0/16`.
