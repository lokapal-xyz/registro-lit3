# Lit3 Ledger

Un contrato inteligente hecho en Solidity para archivar metadatos versionados de artefactos literarios y fragmentos narrativos en la red blockchain de Base. Solo el Curador designado puede añadir o actualizar entradas, lo que lo hace perfecto para proyectos de narración curada, archivos de literatura digital, o cualquier contenido que requiera timestamping inmutable, verificación de contenido y procedencia.

---

## Características

- **Acceso Solo Curador**: Solo el curador designado puede archivar y actualizar entradas
- **Almacenamiento Versionado Inmutable**: Las entradas rastrean el historial de versiones con incremento automático en actualizaciones
- **Verificación de Contenido**: Hash SHA-256 para verificación de texto canónico
- **Integración NFT**: Conexión opcional a contratos NFT para integración coleccionable
- **Metadatos Flexibles**: Campos opcionales para datos NFT y hashes de contenido
- **Soporte Multi-Red**: Despliega a Base Sepolia (testnet) y Base Mainnet
- **Verificación de Contrato**: Verificación automática de código fuente en BaseScan
- **Funciones de Consulta**: Recupera entradas por índice, lote, más recientes o por fuente
- **Integración GraphQL**: Subgraph de The Graph para consultas complejas y actualizaciones en tiempo real

---

## Estructura del proyecto

```
├── src/
│   └── Lit3Ledger.sol               # Contrato principal
├── script/
│   ├── DeployLit3Ledger.s.sol       # Script de despliegue
│   └── InteractWithLit3.s.sol       # Script de interacción para consultas/archivo
├── test/
│   └── Lit3LedgerTest.t.sol         # Suite de pruebas integral
├── scripts/
│   └── hnp1.js                      # Utilidad de normalización de texto y hash SHA-256
├── .env.example                     # Plantilla de variables de entorno
├── deploy-lit3ledger.sh             # Script de despliegue multi-red
├── archive-entry.sh                 # Archivar nuevas entradas con hash opcional
├── archive-updated-entry.sh         # Actualizar entradas anteriores
├── query-lit3.sh                    # Consultar entradas existentes
├── setup-lit3-subgraph.sh           # Script de configuración del Subgraph
├── foundry.toml                     # Configuración de Foundry
└── README.md                        # Este archivo
```

---

## Inicio rápido

### Requisitos previos

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (v18+) - para normalización de texto
- Base Sepolia ETH ([faucet](https://faucet.quicknode.com/base))
- Clave API de BaseScan ([registrarse](https://etherscan.io/apis?id=8453))

### Instalación

1. **Clonar el repositorio:**
```bash
git clone https://github.com/lokapal-xyz/registro-lit3
cd registro-lit3
```

2. **Instalar dependencias de Foundry:**
```bash
forge install
```

3. **Crear archivo de entorno:**
```bash
cp .env.example .env
# Editar .env con tu clave privada y clave API
```

4. **Hacer scripts ejecutables:**
```bash
chmod +x deploy-lit3ledger.sh archive-entry.sh archive-updated-entry.sh query-lit3.sh setup-lit3-subgraph.sh
```

5. **Ejecutar pruebas:**
```bash
forge test
```

### Configuración del entorno

Completa el archivo `.env` con el siguiente contenido:

```bash
# Clave Privada (crea una billetera dedicada para este proyecto)
PRIVATE_KEY=0xTU_CLAVE_PRIVADA_AQUI

# Claves API
BASESCAN_API_KEY=tu_clave_api_basescan_aqui

# URLs de RPC (opcional - usa endpoints públicos por defecto)
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/TU_CLAVE
BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/TU_CLAVE

# Direcciones de Contrato (auto-rellenadas después del despliegue)
CONTRACT_ADDRESS_BASE_SEPOLIA=
CONTRACT_ADDRESS_BASE=

# Dirección de Contrato Activo (auto-rellena después del despliegue)
CONTRACT_ADDRESS=
```

### Despliegue

Despliega a Base Sepolia (testnet) primero:

```bash
./deploy-lit3ledger.sh base-sepolia
```

Para despliegue en mainnet (usa ETH real):

```bash
./deploy-lit3ledger.sh base
```

El script hará:
- Desplegar y verificar el contrato
- Crear archivos JSON de despliegue
- Actualizar tu `.env` con direcciones de contrato
- Proporcionar enlaces de BaseScan

---

## Uso

### Archivar nueva entrada

El script `archive-entry.sh` utiliza **argumentos con nombre (banderas)**, lo que lo hace limpio y fácil de usar con los parámetros opcionales.

#### Sintaxis del comando

El script requiere la bandera `--network`, pero todos los demás parámetros son opcionales y pueden pasarse en cualquier orden.

```bash
./archive-entry.sh --network <red> [BANDERAS OPCIONALES...]
```

#### Banderas opcionales

| Bandera (Corta/Larga) | Descripción | Valor predeterminado en el contrato |
| :--- | :--- | :--- |
| **-t, --title** | Título de la entrada (p. ej., "Capítulo Uno") | `""` (cadena vacía) |
| **-s, --source** | Fuente/ubicación de la entrada | `""` (cadena vacía) |
| **-a, --timestamp1** | Primer sello de tiempo (p. ej., "2025-10-11 14:30:00 UTC") | `""` (cadena vacía) |
| **-b, --timestamp2** | Segundo sello de tiempo (p. ej., "Hora de Lanka") | `""` (cadena vacía) |
| **-c, --curator-note** | Observaciones del Curador | `""` (cadena vacía) |
| **-f, --nft-address** | Dirección del contrato NFT (p. ej., 0x...) | `0x0...0` (dirección cero) |
| **-d, --nft-id** | ID del token NFT | `0` |
| **-l, --text-file** | Ruta a un archivo para el hash de contenido (requiere Node.js) | `0x0...0` (hash cero) |
| **-x, --permaweb-link** | Enlace IPFS/Arweave (p. ej., ipfs://Qm...) | `""` (cadena vacía) |
| **-p, --license** | Declaración de licencia (p. ej., 'CC BY-SA 4.0') | `""` (cadena vacía) |

#### Ejemplos

**Uso básico (Mínimo requerido: Red)**
Archivar una entrada usando solo la bandera de red requerida, más un título y una nota para contexto.

```bash
./archive-entry.sh -n base-sepolia -t "Capítulo Uno" -c "Primera entrada"
```

**Con integración NFT**
Archivar una entrada y asociarla con un NFT específico. Ten en cuenta que las banderas no utilizadas (`--text-file`, etc.) simplemente se omiten.

```bash
./archive-entry.sh \
  --network base-sepolia \
  --title "Capítulo Uno" \
  --source "Nodo de Archivo" \
  --timestamp1 "2025-10-11 14:30:00 UTC" \
  --curator-note "Primera entrada" \
  --nft-address 0x1234567890abcdef1234567890abcdef12345678 \
  --nft-id 42
```

**Con hash de contenido (Marco de Permanencia)**
Archivar una entrada, calcular un hash de contenido desde un archivo local, proporcionar un enlace permaweb y una licencia.

```bash
./archive-entry.sh \
  -n base-sepolia \
  -t "Capítulo Uno" \
  -c "Nota de entrada con hash" \
  -l capítulo-uno.md \
  -x "ipfs://QmTest123" \
  -p "CC BY-SA 4.0"
```

**Entrada completa**
Archivar una entrada con todos los campos opcionales.

```bash
./archive-entry.sh \
  --network base-sepolia \
  --title "Introduccion" \
  --source "Libro 0" \
  --timestamp1 "2025-10-11 UTC" \
  --timestamp2 "2025-12-11 UTC" \
  --curator-note "Primera entrada" \
  --nft-address 0xfC295DBCbB9CCdA53B152AA3fc64dB84d6C538fF \
  --nft-id 0 \
  --text-file placeholder.md \
  --permaweb-link "ipfs://bafkreihrm3tvrubern7kkpxr65ta2zu2cmdkfbfqmcth4eoefly37ke4xq" \
  --license "CC BY-NC-SA 4.0"
```

---

### Normalización de texto y hashing

La utilidad `hnp1.js` aplica normalización estricta para texto de estilo de capítulo:

1. **Eliminación de BOM** - Quita la Marca de Orden de Byte si está presente
2. **Normalización Unicode** - Convierte a forma NFC (caracteres compuestos)
3. **Estandarización de terminaciones de línea** - Todas las líneas se convierten a LF (`\n`)
4. **Eliminación de espacios en blanco finales** - Limpieza por línea
5. **Normalización de tabulaciones** - Todas las tabulaciones se convierten a 4 espacios
6. **Líneas en blanco iniciales/finales eliminadas** - Limpia los límites del documento
7. **Colapso de múltiples líneas en blanco** - Máximo 1 línea en blanco entre contenido
8. **Salto de línea final único** - Hace cumplir el final de archivo consistente

Esto asegura que el mismo texto canónico siempre produce el mismo hash, habilitando verificación.

**Hashing manual:**
```bash
node scripts/hnp1.js /ruta/a/capitulo.md
```

Salida: `0x<64-caracteres-hex-hash>`

---

### Consultar entradas

Obtener estado del contrato:
```bash
./query-lit3.sh base-sepolia status
```

Obtener entradas recientes:
```bash
./query-lit3.sh base-sepolia get-latest 5
```

Obtener entrada específica por índice:
```bash
./query-lit3.sh base-sepolia get-entry 0
```

Todos los comandos de consulta disponibles:
- `status` - Información del contrato y curador actual
- `get-total` - Número total de entradas archivadas
- `get-entry <índice>` - Entrada específica por índice
- `get-latest [cantidad]` - Entradas recientes (por defecto: 5)
- `get-batch <índice_inicio> <cantidad>` - Lote de entradas

---

### Actualizar entrada

El script `archive-updated-entry.sh` también utiliza **argumentos con nombre (banderas)**, requiriendo la red y el índice de la entrada deprecada.

#### Sintaxis del comando

El script requiere las banderas `--network` y `--deprecate-index`. Todos los demás parámetros son opcionales y pueden pasarse en cualquier orden.

```bash
./archive-updated-entry.sh --network <red> --deprecate-index <índice> [BANDERAS OPCIONALES...]
```

#### Banderas opcionales

Las banderas opcionales son las mismas que en `archive-entry.sh` (ver tabla arriba).

#### Ejemplos

**Actualización básica (Mínimo requerido: red e índice)**
Actualizar una entrada, cambiando solo el título y la nota del curador.

```bash
./archive-updated-entry.sh \
  -n base-sepolia \
  -i 5 \
  -t "Capítulo Uno v2" \
  -c "Actualizado con correcciones"
```

**Actualización completa**
Actualizar una entrada con todos los campos opcionales.

```bash
./archive-updated-entry.sh \
  --network base-sepolia \
  --deprecate-index 0 \
  --title "Introduccion" \
  --source "Libro 0" \
  --timestamp1 "2025-10-11 UTC" \
  --timestamp2 "2025-12-11 UTC" \
  --curator-note "Primera entrada" \
  --nft-address 0xfC295DBCbB9CCdA53B152AA3fc64dB84d6C538fF \
  --nft-id 0 \
  --text-file placeholder.md \
  --permaweb-link "ipfs://bafkreihrm3tvrubern7kkpxr65ta2zu2cmdkfbfqmcth4eoefly37ke4xq" \
  --license "CC BY-NC-SA 4.0"
```

---

## API del contrato

### Estructura de entrada

```solidity
struct Entry {
    // Items del marco de registro
    string title;           // Título de la entrada
    string source;          // Fuente/ubicación de la entrada
    string timestamp1;      // Primer timestamp (p. ej., hora de recepción)
    string timestamp2;      // Segundo timestamp (p. ej., hora de transmisión de fuente)
    string curatorNote;     // Observaciones del curador
    bool deprecated;        // Bandera de deprecación
    uint256 versionIndex;   // Número de versión (auto-incrementado)
    // Items del marco de tokens
    address nftAddress;     // Dirección del contrato NFT (0x0 si ninguno)
    uint256 nftId;          // ID de token NFT (0 si ninguno)
    // Items del marco de permanencia
    bytes32 contentHash;    // Hash SHA-256 del texto canónico
    string permawebLink;    // Referencia de almacenamiento decentralizado
    string license;         // Declaracion de licencia
}
```

### Funciones principales

**Archivado:**
- `archiveEntry(título, fuente, timestamp1, timestamp2, notaCurador, dirección_nft, id_nft, contentHash, permawebLink, license)` - Añade nueva entrada (solo curador)
- `archiveUpdatedEntry(título, fuente, timestamp1, timestamp2, notaCurador, dirección_nft, id_nft, contentHash, permawebLink, license, índice_deprecar)` - Crea nueva versión y depreca anterior (solo curador)

**Consultas:**
- `getEntry(uint256 índice)` - Obtiene entrada por índice
- `getTotalEntries()` - Obtiene número total de entradas
- `getLatestEntries(uint256 cantidad)` - Obtiene entradas recientes
- `getEntriesBatch(uint256 inicio, uint256 cantidad)` - Obtiene lote de entradas

**Gobernanza:**
- `initiateCuratorTransfer(address nuevoCurador)` - Inicia transferencia de rol de curador (solo curador)
- `acceptCuratorTransfer()` - Confirma transferencia de rol de curador

---

## Versionado y actualizaciones

El contrato soporta versionado semántico para actualizaciones de entrada:

1. **Primer archivo**: Entrada creada con `versionIndex = 1`
2. **Primera actualización**: Usando `archiveUpdatedEntry()` en índice `n` crea versión 2 y depreca versión 1
3. **Actualizaciones posteriores**: Cada llamada incrementa la versión y depreca la anterior

Tu frontend puede mostrar: "Viendo versión 3 de 5 versiones"

### Flujo de deprecación

```
archive-entry.sh → Entrada v1 (activa)
                ↓
archive-updated-entry.sh → Entrada v1 (deprecated=true), Entrada v2 (activa)
                         ↓
archive-updated-entry.sh → Entrada v2 (deprecated=true), Entrada v3 (activa)
```

---

## Integración con aplicaciones frontend

### Integración con The Graph

Para aplicaciones de producción, integra con The Graph para consultas eficientes:

1. Crea un subgraph indexando los eventos del contrato
2. Usa consultas GraphQL para filtrado complejo y paginación
3. Implementa actualizaciones en tiempo real con suscripciones

- Para ver la implementación completa del Subgraph, [**haz clic aquí**](subgraph-deployment-guide.md)

### Integración con Next.js

Mantén contratos y frontend en repositorios separados:

```
mi-sitio-web/               # Aplicación Next.js
├── lib/
│   └── contracts/           # Copia JSONs de despliegue
└── components/

lit3-ledger/                # Este repositorio
└── deployments/
```

Copia archivos de despliegue cuando sea necesario:
```bash
cp deployments/base.json ../mi-sitio-web/lib/contracts/
```

---

## Información de redes

### Base Sepolia (Testnet)
- Chain ID: 84532
- RPC: https://sepolia.base.org
- Explorador: https://sepolia.basescan.org
- Faucet: https://faucet.quicknode.com/base

### Base Mainnet
- Chain ID: 8453
- RPC: https://mainnet.base.org
- Explorador: https://basescan.org

---

## Consideraciones de seguridad

- **Rol de Curador**: Solo el curador puede añadir/actualizar entradas. Transfiere este rol cuidadosamente
- **Clave Privada**: Usa una billetera dedicada para operaciones de contrato
- **Testnet Primero**: Siempre prueba en Base Sepolia antes del despliegue en mainnet
- **Verificación de Hash de Contenido**: Verifica hashes canónicos ejecutando la normalización localmente
- **Inmutabilidad**: Solo la última versión es "activa" (`deprecated = false`). Todas las versiones permanecen en la cadena para auditoría

---

## Pruebas

Ejecuta la suite de pruebas integral:

```bash
# Ejecutar todas las pruebas
forge test

# Ejecutar con reporte de gas
forge test --gas-report

# Ejecutar prueba específica
forge test --match-test testArchiveEntry

# Ejecutar con salida verbose
forge test -vvv
```

Las pruebas cubren:
- Despliegue e inicialización
- Archivado de entrada y versionado
- Archivado de entrada actualizada con depreciación
- Control de acceso (funciones solo curador)
- Funciones de recuperación y casos límite
- Emisión de eventos
- Pruebas de cadena de versionado
- Pruebas fuzz para casos límite

---

## Casos de uso

Este patrón de contrato es adecuado para:
- Proyectos de literatura digital y narración
- Archivo de contenido con procedencia y versionado
- Almacenamiento de metadatos con timestamp
- Proyectos de arte digital curado con múltiples versiones
- Investigación académica con registros inmutables y control de versiones
- Comunidades de escritura creativa con flujos editoriales
- Proyectos de ficción interactiva con narrativas ramificadas
- Plataformas de publicación que requieren verificación de contenido

---

## Aviso de seguridad

Este contrato **no ha sido auditado formalmente** por una firma de seguridad de terceros. Aunque el código ha sido ampliamente probado en testnet Sepolia y revisado para vulnerabilidades comunes, aún puede contener bugs o problemas de seguridad.

**Úsalo bajo tu propio riesgo.** Si pretendes desplegar este contrato con activos reales o valor significativo:

- Considera obtener una auditoría de seguridad formal de una firma reputada
- Despliega en testnet primero y prueba a fondo con tu caso de uso
- Haz que el contrato sea revisado por desarrolladores Solidity experimentados
- Usa suposiciones conservadoras sobre vulnerabilidades potenciales
- Considera implementar estrategias de despliegue gradual y monitoreo

Los autores y contribuidores no son responsables por pérdidas o daños resultantes del uso de este código.

---

## Licencia

Licencia MIT - ver archivo LICENSE para detalles

## Soporte

- Crea un issue para bugs o solicitudes de características
- Verifica issues existentes antes de crear nuevos
- Proporciona información detallada incluyendo red, hashes de transacciones y mensajes de error

---

Construido con Foundry por lokapal.eth