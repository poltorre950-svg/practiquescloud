# Práctica Pt2.2 — Cloud Computing

Infraestructura en AWS con Terraform: VPC, dos subredes públicas, Internet Gateway, tabla de rutas, grupo de seguridad y dos instancias EC2 t3.micro.

## Estructura

```
practiquescloud/
└── pt2-2/
    ├── assets/    # Capturas de pantalla de validación
    ├── main.tf    # Código Terraform
    └── README.md  # Este documento
```

## Recursos implementados

| Componente | Configuración |
|---|---|
| Proveedor | AWS, región `us-east-1` |
| VPC | `VPC-03`, `10.0.0.0/16` |
| Subred pública A | `us-east-1a`, `10.0.1.0/24`, IP pública automática |
| Subred pública B | `us-east-1b`, `10.0.2.0/24`, IP pública automática |
| Internet Gateway | Adjunto a `VPC-03` |
| Tabla de rutas | `0.0.0.0/0 → Internet Gateway`, asociada a ambas subredes |
| Grupo de seguridad | SSH (22) desde `0.0.0.0/0`; ICMP desde `10.0.0.0/16`; egress abierto |
| EC2 `ec2-a` | `t3.micro`, Amazon Linux, Subred A, clave `vockey` |
| EC2 `ec2-b` | `t3.micro`, Amazon Linux, Subred B, clave `vockey` |

AMI resuelta mediante `data "aws_ami"` (Amazon Linux 2023).

## Despliegue

```bash
cd practiquescloud/pt2-2
terraform init
terraform plan
terraform apply
```

Destrucción:

```bash
terraform destroy
```

## Capturas de pantalla

Incluir en `assets/`:

1. `terraform-init.png`
2. `terraform-plan.png`
3. `terraform-apply.png`
4. `vpc.png`
5. `subnets.png`
6. `routes.png`
7. `security-group.png`
8. `ec2-instances.png`

## Requisitos previos

- Terraform instalado
- AWS CLI configurado en `us-east-1`
- Par de claves `vockey` existente en `us-east-1`
