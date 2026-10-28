# Ejercicio 1: Primeres instàncies EC2 amb Terraform

Despliegue de **dos instancias EC2 `t3.micro`** con **Amazon Linux 2023** en la región **`us-east-1`** mediante Terraform, usando la AMI gratuita `ami-04b938437b69a2c9c`.

## Objetivo

Practicar el ciclo de vida básico de Terraform (`init` → `plan` → `apply` → `destroy`) creando instancias EC2 **sin diseñar una red propia**: se reutiliza la VPC por defecto de AWS para centrar el ejercicio en el recurso `aws_instance` y en el uso de `count`.

## Topología de red

![Topología de Red](assets/topologia.png)

> **Nota:** la arquitectura fue diseñada en **draw.io**.

Terraform utiliza la VPC por defecto de AWS, que asigna automáticamente subred, Security Group e IP pública a las instancias.

```
Internet
   │
   ▼
VPC por defecto (us-east-1)
├── Subred por defecto (AZ asignada por AWS)
│   ├── Instancia-1  (t3.micro, Amazon Linux 2023)
│   └── Instancia-2  (t3.micro, Amazon Linux 2023)
└── Security Group por defecto
```

## Recursos creados

| Recurso | Dirección Terraform | Nombre en AWS | Detalle |
|---------|---------------------|---------------|---------|
| Instancia EC2 | `aws_instance.web[0]` | `Instancia-1` | `t3.micro`, AMI `ami-04b938437b69a2c9c` |
| Instancia EC2 | `aws_instance.web[1]` | `Instancia-2` | `t3.micro`, AMI `ami-04b938437b69a2c9c` |

Total: **2 instancias**. No se crea VPC, subred, Security Group ni clave SSH: todo eso lo aporta la configuración por defecto de la cuenta.

## Estructura

```text
pt1-4-ex1/
├── assets/
│   └── topologia.png
├── main.tf                 # configuración de Terraform
├── README.md
├── .terraform.lock.hcl     # versiones exactas del proveedor (se versiona)
├── .terraform/             # proveedor descargado (ignorado por git)
└── terraform.tfstate       # estado local (ignorado por git)
```

`.terraform/` y `terraform.tfstate` se generan al ejecutar Terraform y **no deben subirse al repositorio**: el primero pesa cientos de MB y el segundo puede contener datos sensibles.

## Configuración (`main.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  count = 2

  # AMI gratuita de Amazon Linux 2023 en us-east-1.
  ami           = "ami-04b938437b69a2c9c"
  instance_type = "t3.micro"

  tags = {
    Name = "Instancia-${count.index + 1}"
  }
}
```

- **`provider "aws"`**: fija la región `us-east-1`; las credenciales se toman del entorno (`AWS_*`) o de `~/.aws/credentials`.
- **`count = 2`**: crea dos instancias idénticas, accesibles como `aws_instance.web[0]` y `web[1]`.
- **`ami`**: identificador fijo de Amazon Linux 2023; al estar fijado, el plan es reproducible y no cambia si Amazon publica una AMI nueva.
- **`tags.Name`**: usa `count.index` para nombrar las instancias `Instancia-1` e `Instancia-2`.

## Requisitos

- Terraform **1.5 o superior** (probado con 1.16).
- Credenciales de AWS con permisos sobre EC2 (en AWS Academy, las credenciales de la sesión del laboratorio).
- La imagen `assets/topologia.png` debe existir para visualizarla en este README.
- Conexión a internet para descargar el proveedor en el primer `init`.

## Procedimiento

1. **Inicializar Terraform.** Descarga el proveedor de AWS y prepara el directorio.

   ```bash
   cd pt1-4-ex1
   terraform init
   ```

2. **Formatear y validar (opcional, recomendado).**

   ```bash
   terraform fmt -check
   terraform validate
   ```

3. **Revisar el plan.** Muestra los cambios sin crear nada. Deben aparecer dos instancias EC2.

   ```bash
   terraform plan
   # Plan: 2 to add, 0 to change, 0 to destroy.
   ```

4. **Crear la infraestructura.** Solicita confirmación y despliega las dos instancias.

   ```bash
   terraform apply
   # Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
   ```

5. **Verificar.** En la consola de AWS, dentro de **EC2 → Instances** en `us-east-1`, deben aparecer las instancias `Instancia-1` e `Instancia-2`. También se puede comprobar desde la terminal:

   ```bash
   terraform state list
   terraform state show 'aws_instance.web[0]' | grep -E 'id|public_ip|private_ip|instance_state'
   ```

6. **Destruir los recursos.** Elimina las instancias para evitar costes.

   ```bash
   terraform destroy
   ```

## Verificación y acceso

Este ejercicio **no define `key_name` ni reglas de Security Group**, por lo que las instancias no admiten SSH tal cual: solo se comprueba su creación y estado. Para conectarse habría que añadir una clave (`aws_key_pair`), abrir el puerto 22 en un Security Group y asociarlo a la instancia.

Comprobación rápida del estado:

```bash
terraform state show 'aws_instance.web[1]' | grep instance_state
# instance_state = "running"
```

## Costes

- 2 × `t3.micro` en `us-east-1`. La capa gratuita de AWS cubre **750 horas al mes de una sola** instancia `t3.micro` (12 meses); dos instancias consumen el doble.
- El almacenamiento EBS asociado (8 GiB por defecto) también puede generar coste fuera de la capa gratuita.
- Ejecuta siempre `terraform destroy` al terminar la práctica.

## Problemas comunes

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `ExpiredToken` / `InvalidClientTokenId` | Credenciales del laboratorio caducadas | Volver a copiar las credenciales de AWS Academy en `~/.aws/credentials` |
| `InvalidAMIID.NotFound` | La AMI no existe en la región configurada | Usar una AMI de `us-east-1` o cambiar `region` |
| `VcpuLimitExceeded` | Límite de vCPU de la cuenta | Solicitar aumento de cuota o reducir instancias |
| El estado no coincide con AWS | Recursos modificados a mano | `terraform refresh` (o `terraform plan -refresh-only`) |
| El push a GitHub falla por tamaño | Se añadió `.terraform/` al repositorio | Mantener el `.gitignore`; nunca versionar `.terraform/` ni `*.tfstate` |

## Limpieza

```bash
terraform destroy
# Destroy complete! Resources: 2 destroyed.
```
