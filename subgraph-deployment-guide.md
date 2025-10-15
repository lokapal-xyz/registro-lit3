# Guía de implementación de Subgraph

Esta guía detalla los pasos necesarios para configurar, compilar e implementar el Subgraph de Lit3 Ledger en **The Graph Studio**.

## Estructura del proyecto Subgraph

Los archivos y directorios clave dentro del proyecto son:

| Archivo/Directorio | Descripción |
| :--- | :--- |
| `setup-subgraph.sh` | El script ejecutable principal para instalar la CLI, gestionar dependencias y ejecutar la generación de código/compilación. |
| `subgraph/` | El directorio raíz para los archivos del proyecto subgraph. |
| `subgraph/abis/` | Contiene el **archivo ABI JSON del contrato (`Lit3Ledger.json`)** utilizado por el generador de código. |
| `subgraph/src/` | Contiene la **lógica de mapeo de AssemblyScript (`lit3-ledger.ts`)** que maneja eventos blockchain. |
| `subgraph/networks.json` | Archivo de configuración que define los puntos finales de la red para desarrollo/pruebas. |
| `subgraph/package.json` | Manifiesto del proyecto que define dependencias y scripts de implementación (`pnpm run deploy`). |
| `subgraph/schema.graphql` | Define el modelo de datos GraphQL (entidades) para tu subgraph. |
| `subgraph/subgraph.yaml` | El manifiesto del subgraph que vincula el contrato, ABI, esquema y funciones de mapeo. |

-----

## Preparación para la implementación

### Paso 1: Configurar detalles del contrato

Antes de ejecutar el script de configuración, debes actualizar la configuración del subgraph con la información de tu contrato desplegado.

1.  **Obtener Detalles:** Localiza tu dirección de contrato y número de bloque de implementación en la salida de implementación de tu proyecto (p. ej., `deployments/base.json`).

    ```json
    {
      "contractAddress": "TU_DIRECCION_DE_CONTRATO_AQUI",
      "blockNumber": "TU_NUMERO_DE_BLOQUE_DE_DESPLIEGUE",
      // ...
    }
    ```

2.  **Actualizar Manifiesto:** Abre `subgraph/subgraph.yaml` y actualiza los campos `address` y `startBlock` bajo la sección `dataSources`, y establece el campo `network` en tu red de trabajo:

    ```yaml
      network: "TU_RED_DE_CONTRATO"
      source:
        address: "TU_DIRECCION_DE_CONTRATO_AQUI"
        abi: Lit3Ledger
        startBlock: "TU_NUMERO_DE_BLOQUE_DE_DESPLIEGUE"
    ```

3.  **Actualizar `networks.json`:** Abre `subgraph/networks.json` y actualiza los valores del contrato `Lit3Ledger` para la red que estás utilizando (p. ej., `base-sepolia`).

    ```json
    // En subgraph/networks.json
    "base-sepolia": {
      "Lit3Ledger": {
        "address": "TU_DIRECCION_DE_CONTRATO_AQUI",
        "startBlock": "TU_NUMERO_DE_BLOQUE_DE_DESPLIEGUE"
      }
    },
    // ...
    ```

### Paso 2: Configurar nombre del proyecto

Abre `subgraph/package.json` y reemplaza `"TU_NOMBRE_DE_PROJECTO"` con el **slug/nombre exacto** que planeas usar en The Graph Studio (p. ej., `lit3-ledger-base`).

```json
{
  "name": "TU_NOMBRE_DE_PROJECTO",
  "scripts": {
    "deploy": "graph deploy TU_NOMBRE_DE_PROJECTO",
    // ...
  }
}
```

-----

## Configuración Local y Compilación

Este paso utiliza el script automatizado para instalar las herramientas necesarias, dependencias y generar los archivos de compilación finales.

1.  **Otorgar permiso de ejecución:**

    ```bash
    chmod +x setup-lit3-subgraph.sh
    ```

2.  **Ejecutar script de configuración:**

    ```bash
    ./setup-lit3-subgraph.sh
    ```

    > ⚠️ **Verificación de configuración de pnpm:** Si es la primera vez que usas `pnpm` para instalaciones globales, el script te pedirá que ejecutes `pnpm setup` y luego reinicies tu terminal antes de intentar de nuevo.

## Implementación en The Graph Studio

Una vez que el script se complete exitosamente, tu subgraph está compilado y listo para ser implementado.

1.  **Crear Subgraph en Studio:**

      * Visita **[The Graph Studio](https://thegraph.com/studio/)** y conecta tu wallet.
      * Haz clic en **"Create a Subgraph"** y crea un nuevo proyecto usando el **nombre/slug exacto** definido en tu `package.json`.

2.  **Obtener clave de implementación:**

      * En la página de detalles de tu nuevo subgraph, localiza y **copia tu Clave de Implementación única**.

3.  **Autenticar CLI:**

      * Navega al directorio de tu subgraph:
        ```bash
        cd subgraph
        ```
      * Ejecuta el comando de autenticación usando la clave que copiaste:
        ```bash
        graph auth <TU_CLAVE_AQUI>
        ```

4.  **Implementar el Subgraph:**

      * Ejecuta el script de implementación definido en tu `package.json`. El script usará automáticamente el nombre del proyecto que definiste.
        ```bash
        pnpm run deploy
        # O: graph deploy <TU_NOMBRE_DE_PROJECTO>
        ```
      * Cuando la CLI te lo solicite, ingresa una **etiqueta de versión** (p. ej., `v0.0.1`).

-----

## Pasos finales

1.  **Monitorear estado:** Regresa a The Graph Studio. Tu subgraph debería comenzar a sincronizarse casi inmediatamente. Monitorea la pestaña **Logs** por si hay errores.
2.  **Consultar datos:** Una vez que el subgraph esté completamente sincronizado (o parcialmente sincronizado pasando tu bloque de inicio), puedes **Probar consultas** en el Playground de GraphQL integrado.
3.  **Endpoint listo:** Ahora puedes usar tu punto final GraphQL generado para integrar los datos en tu aplicación.