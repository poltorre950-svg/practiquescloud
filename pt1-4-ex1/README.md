# Ejercicio 1: Primeres instàncies EC2 amb Terraform

Despliegue de **dos instancias EC2 `t3.micro`** con **Amazon Linux 2023** en la región **`us-east-1`** mediante Terraform, usando la AMI gratuita `ami-04b938437b69a2c9c`.

## Topología de red

![Topología de Red](assets/topologia.png)

> **Nota:** la arquitectura fue diseñada en **draw.io**.

Terraform utiliza la VPC por defecto de AWS, que asigna automáticamente subred, Security Group e IP pública a las instancias.

## Estructura

```text
pt1-4-ex1/
├── assets/
│   └── topologia.png
├── README.md
└── main.tf
```

## Configuración

- Proveedor de AWS en `us-east-1`.
- AMI fija `ami-04b938437b69a2c9c`.
- Dos instancias `t3.micro` creadas con `count = 2`.
- Tags dinámicos: `Instancia-1` e `Instancia-2`.

## Requisitos

- Terraform instalado.
- Credenciales de AWS configuradas (`aws configure`).
- La imagen `assets/topologia.png` debe existir para visualizarla en este README.

## Procedimiento

1. **Inicializar Terraform.** Descarga el proveedor de AWS y prepara el directorio.

   ```bash
   terraform init
   ```

2. **Revisar el plan.** Muestra los cambios sin crear nada. Deben aparecer dos instancias EC2.

   ```bash
   terraform plan
   ```

3. **Crear la infraestructura.** Solicita confirmación y despliega las dos instancias.

   ```bash
   terraform apply
   ```

4. **Verificar.** En la consola de AWS, dentro de **EC2 → Instances** en `us-east-1`, deben aparecer las instancias `Instancia-1` e `Instancia-2`.

5. **Destruir los recursos.** Elimina las instancias para evitar costes.

   ```bash
   terraform destroy
   ```
