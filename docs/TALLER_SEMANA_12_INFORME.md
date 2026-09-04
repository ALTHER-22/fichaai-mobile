# TALLER PRÁCTICO – SEMANA 12
## Persistencia Local y Almacenamiento Seguro del Proyecto Móvil "FichaAI"

---

### Información General del Proyecto
* **Asignatura:** Desarrollo de Aplicaciones Móviles
* **Proyecto Integrador:** FichaAI – Asistente y Gestor de Fichas Técnicas Oficiales de Smartphones
* **Framework Móvil:** Flutter (Dart 3.13 / Flutter 3.47)
* **Backend:** Python Flask API + PostgreSQL (con Cache-Aside y Workers asíncronos)
* **Repositorio Móvil (GitHub):** [https://github.com/ALTHER-22/fichaai-mobile.git](https://github.com/ALTHER-22/fichaai-mobile.git)
* **Repositorio Backend (GitHub):** [https://github.com/ALTHER-22/fichaai-backend.git](https://github.com/ALTHER-22/fichaai-backend.git)

---

## 1. Clasificación de Datos y Elección de Mecanismos

Conforme a las directrices de arquitectura móvil y persistencia offline-first, los datos de la aplicación **FichaAI** se han clasificado estrictamente en cuatro categorías según su nivel de sensibilidad, volatilidad y requerimientos de consulta:

| Clase de Dato | Ejemplos en FichaAI | Sensibilidad | Mecanismo Idóneo Seleccionado | Justificación Técnica y de Salud de Mantenimiento |
| :--- | :--- | :---: | :--- | :--- |
| **Credenciales y Secretos** | Tokens JWT de acceso (`token`), nombres de usuario y roles administrativos. | **Alta (Crítica)** | **Almacenamiento Cifrado del SO** (`flutter_secure_storage` -> Android Keystore / iOS Keychain / Windows DPAPI). | **Regla de oro:** Los tokens jamás deben guardarse en texto plano ni en SharedPreferences. Se utiliza `flutter_secure_storage` con cifrado por hardware (`encryptedSharedPreferences: true`). Cuenta con más de 8,000 likes en pub.dev, publicaciones regulares y mantenimiento activo continuo. |
| **Datos del Dominio y Caché** | Catálogo oficial de especificaciones técnicas de smartphones (pantallas, procesadores, cámaras, batería, precios). | **Media / Baja** | **Base de Datos Relacional Local** (`sqflite` + `sqflite_common_ffi`). | Requiere consultas indexadas, ordenamientos por fecha y soporte para transacciones. SQLite es el estándar industrial más probado del mundo, garantizando cero riesgo de abandono frente a motores propietarios. |
| **Cola de Escrituras Offline (Outbox)** | Operaciones pendientes de creación/edición creadas sin red, con UUID de cliente, intentos y payloads. | **Media** | **Tabla SQLite de Cola Outbox** (`cola_operaciones`). | Garantiza durabilidad transaccional ACID en el cliente. Si el usuario cierra o apaga el dispositivo, las escrituras pendientes no se pierden en memoria. |
| **Preferencias y Ajustes** | Modo visual (tema claro/oscuro), filtros preferidos de visualización. | **Nula** | **Almacén de Clave y Valor** (`shared_preferences`). | Optimizado exclusivamente para tipos primitivos simples (booleanos, strings). No almacena listas pesadas ni credenciales. |
| **Archivos Pesados y Medios** | Imágenes descargadas de dispositivos, reportes técnicos generados. | **Baja** | **Sistema de Archivos Nativo** (`path_provider` con ruta persistida en BD). | La base de datos solo almacena URIs relativas; el archivo binario reside en el sandbox de almacenamiento del sistema operativo. |

---

## 2. Criterio de Selección Técnico y Salud del Mantenimiento

### ¿Por qué SQLite (`sqflite`) y descarte de alternativas?
1. **Riesgo de abandono comprobado en el ecosistema (`Hive` e `Isar`):**
   * Librerías NoSQL como `Hive` e `Isar`, a pesar de su popularidad sintética inicial, sufrieron largos periodos de inactividad y abandono por parte de sus autores individuales, provocando rupturas críticas ante actualizaciones del SDK de Dart y obligando a los equipos a costosas migraciones de emergencia.
2. **Estabilidad y compatibilidad de `sqflite`:**
   * Basado en el motor de base de datos C SQLite estándar. Es mantenido de manera oficial y activa por la comunidad de Flutter.
   * La inclusión de `sqflite_common_ffi` permite compilar y ejecutar nativamente en entornos de escritorio (Windows Desktop, Linux, macOS) y ejecutar pruebas unitarias automatizadas (`flutter test`) de forma instantánea sin requerir emuladores pesados.
3. **Seguridad del sistema operativo (`flutter_secure_storage`):**
   * En Android delega la clave de cifrado al módulo **Android Keystore**, asegurando que ni siquiera mediante ingeniería inversa o root básico se puedan extraer los tokens JWT. En iOS utiliza el **Keychain Services API** con atributo `kSecAccessControlBiometryAny`.

---

## 3. Esquema de Base de Datos Local y Principio de Minimización

### Principio de Minimización de Datos
En estricto cumplimiento del principio de minimización, la tabla local no duplica campos redundantes de auditoría interna del backend (como logs de tareas Celery o contraseñas hash). Únicamente almacena los atributos necesarios para renderizar las tarjetas y fichas técnicas en la interfaz móvil, complementados con columnas de sincronización.

### Definición del Esquema DDL (`DatabaseHelper.dart`)

```sql
-- Tabla Principal de Catálogo (Fichas Técnicas)
CREATE TABLE fichas (
    id_local TEXT PRIMARY KEY,               -- UUID generado en cliente para identidad local
    id_servidor TEXT,                        -- UUID asignado por el servidor backend
    modelo TEXT NOT NULL,                    -- Modelo del teléfono (ej: Galaxy A55)
    fabricante TEXT,                         -- Fabricante (Samsung, Xiaomi, etc.)
    procesador TEXT,                         -- Chipset principal
    ram TEXT,                                -- Capacidad de RAM
    almacenamiento TEXT,                     -- Capacidad de ROM
    pantalla TEXT,                           -- Especificación de panel
    camara_principal TEXT,                   -- Sensor principal
    camara_frontal TEXT,                     -- Sensor selfie
    bateria TEXT,                            -- Batería y velocidad de carga
    sistema_operativo TEXT,                  -- Versión de SO
    conectividad TEXT,                       -- Redes 5G / Wi-Fi / NFC
    extras TEXT,                             -- Certificación IP, Gorilla Glass
    precio_oficial REAL,                     -- Precio en USD (validado > 0)
    moneda TEXT DEFAULT 'USD',               -- Moneda oficial
    url_imagen TEXT,                         -- Enlace de imagen oficial
    sincronizado INTEGER NOT NULL DEFAULT 1, -- 0 = Creado offline, 1 = Sincronizado
    fecha_servidor TEXT,                     -- Timestamp ISO del servidor para LWW
    fecha_guardado_local TEXT NOT NULL       -- Timestamp cliente para cálculo de antigüedad
);

-- Tabla de Salida (Patrón Outbox para Resiliencia Offline)
CREATE TABLE cola_operaciones (
    id_operacion TEXT PRIMARY KEY,           -- UUID cliente único (Idempotencia)
    tipo_operacion TEXT NOT NULL,            -- 'CREAR_FICHA', 'ACTUALIZAR_FICHA', 'ELIMINAR_FICHA'
    id_entidad_local TEXT NOT NULL,          -- Referencia al id_local de la ficha
    payload TEXT NOT NULL,                   -- JSON serializado con los atributos
    intentos INTEGER NOT NULL DEFAULT 0,     -- Contador de intentos ejecutados
    max_intentos INTEGER NOT NULL DEFAULT 5, -- Límite máximo de reintentos
    estado TEXT NOT NULL DEFAULT 'pendiente',-- 'pendiente', 'en_proceso', 'fallido'
    creado_en TEXT NOT NULL,                 -- Marca de tiempo de registro
    ultimo_error TEXT                        -- Mensaje de diagnóstico del último fallo
);
```

### Migraciones Versionadas en el Cliente
Las migraciones se controlan mediante `schemaVersion = 1` y el hook `onUpgrade(db, oldVersion, newVersion)`. A diferencia del servidor donde se pueden reconstruir esquemas en staging, en el dispositivo del usuario **nunca se destruye la base de datos**, sino que se ejecutan sentencias incrementales `ALTER TABLE` para preservar los registros locales no sincronizados del usuario.

---

## 4. Lectura sin Conexión e Indicador Visible de Antigüedad

En la pantalla del **Catálogo de Dispositivos** (`ListadoFichasScreen`):
1. **Acceso Offline Inmediato:** Al abrir la pantalla, los datos se leen directamente desde SQLite en menos de 10 milisegundos sin esperar respuesta de red.
2. **Banner de Estado y Modo Avión:**
   * Cuando el dispositivo entra en modo avión o pierde conectividad (`ConnectivityService`), se despliega un banner superior de alta visibilidad con icono de avión (`Icons.airplanemode_active`):
     > **"MODO SIN CONEXIÓN (MODO AVIÓN ACTIVO)"**
     > *Mostrando datos almacenados en SQLite local. Antigüedad del catálogo: Hace X min (DD/MM/AAAA HH:mm:ss). Advertencia: los datos pueden estar desactualizados respecto al servidor.*
3. **Badges Individuales por Ficha Técnica:**
   * Cada tarjeta de dispositivo (`TarjetaFicha`) muestra en su esquina superior derecha un chip de estado:
     * **🟡 Offline / Pendiente:** Si fue creada sin conexión (`sincronizado == false`).
     * **🟢 Sincronizado:** Si ya cuenta con confirmación del servidor.

---

## 5. Escritura sin Conexión y Cola Outbox con Reintentos Exponenciales

### Flujo de Escritura Fuera de Línea
1. El usuario administrador llena el formulario de registro de un nuevo smartphone con el dispositivo en **Modo Avión**.
2. **Generación de UUID de Idempotencia:** La aplicación genera mediante la librería `uuid` un identificador único para la ficha (`idLocal`) y para la operación (`idOperacion`).
3. **Actualización Optimista:** La ficha se inserta inmediatamente en la tabla local `fichas` con `sincronizado = 0` y se refleja al instante en la lista de la interfaz de usuario.
4. **Encolado en Outbox:** La operación se inserta en `cola_operaciones` con estado `'pendiente'` y `intentos = 0`.

### Algoritmo de Reintentos con Backoff Exponencial
Cuando la red se restablece o se pulsa el botón de sincronización, el worker `SyncService` procesa las operaciones pendientes aplicando una función de espera creciente:

$$\text{Tiempo de Espera} = \min(30, 2^{\text{intentos}}) \text{ segundos}$$

* Intento 0: 1 segundo
* Intento 1: 2 segundos
* Intento 2: 4 segundos
* Intento 3: 8 segundos
* Intento 4: 16 segundos
* Intento 5: 30 segundos (tope máximo)

Si tras 5 intentos el servidor sigue sin responder o rechaza con error permanente, la operación pasa al estado `'fallido'` para no saturar la batería ni el ancho de banda del usuario, manteniendo el registro local intacto para posterior resolución.

### Idempotencia en el Servidor
Cada solicitud HTTP enviada al endpoint `POST /api/fichas` incorpora la cabecera HTTP:
`Idempotency-Key: <id_operacion_uuid>`
Esto garantiza que si la respuesta de red se corta tras la inserción en el servidor, un reintento posterior del cliente no duplicará el registro en PostgreSQL.

---

## 6. Estrategia de Resolución de Conflictos

### Estrategia Adoptada: La última escritura gana (Last-Write-Wins - LWW)
* **Fuente de la Marca Temporal:** Las marcas temporales de reconciliación proceden **estrictamente del servidor backend** (`fecha_servidor` / `fecha_generacion`) y **nunca del reloj del dispositivo móvil**, evitando vulnerabilidades por desfase horario intencional o automático del cliente.
* **Mecanismo de Decisión:**
  * Al descargar o sincronizar registros del servidor, se compara la marca temporal `fecha_servidor` del backend con la almacenada localmente.
  * Si la fecha del servidor es más reciente o igual a la local, SQLite actualiza el registro local.
  * Si la ficha local tiene `sincronizado == false` (escritura offline pendiente), se prioriza la escritura local encolada hasta que el servidor la procese y le asigne su nueva marca de tiempo oficial.

### Declaración Explícita de lo que Sacrifica la Estrategia LWW
> [!WARNING]
> **SACRIFICIO DECLARADO:**
> La estrategia **Last-Write-Wins (LWW)** sacrifica cualquier modificación concurrente anterior realizada por otro cliente o administrador sobre la misma ficha, sobrescribiéndola de manera silenciosa sin solicitar confirmación manual al usuario. Se asume esta limitación a cambio de garantizar fluidez total, ausencia de bloqueos interactivos en la interfaz móvil y convergencia determinista hacia la versión del servidor.

---

## 7. Registro de Protección de Datos Personales (Normativa LOPDP Ecuador)

En cumplimiento de la **Ley Orgánica de Protección de Datos Personales (LOPDP)** de la República del Ecuador y las disposiciones de la **Superintendencia de Protección de Datos Personales (SPDP)**:

### Tabla de Registro de Actividades de Tratamiento Local
| Categoría de Dato Personal | Datos Específicos Almacenados | Finalidad Legítima del Tratamiento | Plazo Máximo de Conservación | Base Legal (LOPDP) |
| :--- | :--- | :--- | :--- | :--- |
| **Identificación de Usuario** | Correo electrónico institucional / corporativo y nombre de usuario. | Identificación del autor de las fichas técnicas registradas y auditoría de cambios. | Estrictamente durante la sesión activa en el terminal. | Art. 7 (Consentimiento y legitimidad del tratamiento). |
| **Credenciales Criptográficas** | Token JWT de acceso y autorización con claims de rol (`admin`/`user`). | Mantener la sesión autenticada segura y autorizar peticiones protegidas al backend. | Hasta la expiración natural del token o el cierre de sesión voluntario. | Art. 10 (Seguridad y confidencialidad). |
| **Registros Técnicos Locales** | Borradores de fichas técnicas encoladas offline. | Continuidad operativa fuera de línea del analista técnico. | Hasta su sincronización exitosa o purga manual. | Art. 12 (Principio de lealtad y minimización). |

### Procedimiento de Supresión Total (Logout Seguro)
Al presionar el botón de **Cerrar Sesión** (`AuthProvider.logout()`):
1. Se invoca `SecureStorageService.eliminarSesion()`, purgando de manera irreversible las claves del **Android Keystore / iOS Keychain**.
2. Se invoca `DatabaseHelper.purgarTodo()`, ejecutando `DELETE FROM fichas` y `DELETE FROM cola_operaciones`.
3. Se invoca `FichaProvider.limpiarMemoria()`, limpiando el árbol de estado en RAM.
4. Se notifica al usuario en pantalla la confirmación de la purga total en cumplimiento de los **Artículos 15 (Derecho de Supresión)** y **21 (Principio de Seguridad)** de la LOPDP ecuatoriana.

---

## 8. Guion Paso a Paso para la Grabación del Video Explicativo

Para obtener el puntaje completo (10/10) en la evaluación de la ingeniera, sigue este orden exacto durante la grabación del video (duración recomendada: 3 a 5 minutos):

### Demostración 1: Sesión conservada tras reiniciar la aplicación (2.0 pts)
1. Iniciar la aplicación y pulsar sobre el icono de usuario o **"Registrar Ficha (Admin)"** para abrir la pantalla de **Login**.
2. Iniciar sesión con `admin@fichaai.com` / `admin1234`. Mostrar el mensaje de bienvenida y el chip de usuario activo.
3. **Cerrar por completo la aplicación móvil** (cerrar la ventana de Windows Desktop o forzar detención / swipe out en el emulador Android).
4. **Reabrir la aplicación**: Mostrar que el usuario **sigue autenticado automáticamente**, sin volver a pedir contraseña, gracias a que el token JWT fue recuperado desde el almacenamiento cifrado del sistema operativo (`flutter_secure_storage`).

### Demostración 2: Listado funcionando en Modo Avión con indicador de antigüedad (1.5 pts)
1. Navegar a la pantalla del **Catálogo de Dispositivos**.
2. **Activar el Modo Avión** en el emulador (o desconectar la red Wi-Fi/Ethernet en la computadora).
3. Mostrar cómo la aplicación detecta el cambio en tiempo real y despliega el **Banner Ámbar**:
   * Icono de avión activo.
   * Texto: *"MODO SIN CONEXIÓN (MODO AVIÓN ACTIVO)"*.
   * Antigüedad de los datos: *"Mostrando datos almacenados en SQLite local. Antigüedad del catálogo: Hace X min (DD/MM/AAAA HH:mm:ss). Advertencia: los datos pueden estar desactualizados."*
4. Navegar entre las fichas locales para evidenciar que la lectura es instantánea y no se bloquea.

### Demostración 3: Creación de registro sin conexión y sincronización Outbox al reconectar (2.0 pts)
1. Con el **Modo Avión aún activo**, presionar el botón flotante **"+ Nueva Ficha"**.
2. Llenar el formulario con un dispositivo nuevo (ej: *Google Pixel 9 Pro*, Fabricante: *Google*, Precio: *999.0*).
3. Presionar **"Guardar y Publicar Ficha"**.
4. Mostrar el SnackBar afirmativo: *"Modo sin conexión: Ficha guardada en SQLite local y encolada en Outbox con UUID único."*
5. En el Catálogo, señalar que el nuevo teléfono aparece de inmediato en la lista con el distintivo: **"🟡 Offline / Pendiente"** y el contador en la parte superior indica *"1 operación pendiente en cola Outbox"*.
6. **Desactivar el Modo Avión / Reactivar Conexión a Internet**:
   * Mostrar cómo el worker de sincronización procesa automáticamente la cola (o pulsar el icono de sincronización con reintentos).
   * Mostrar el cambio de estado en vivo: la ficha pasa inmediatamente a tener el distintivo **"🟢 Sincronizado"** y el contador de pendientes se reduce a 0.

### Demostración 4: Cierre de sesión y purga total del almacén local (0.5 pts)
1. Volver al inicio / buscador y presionar el botón de **Cerrar Sesión** en la barra superior.
2. Señalar el mensaje en pantalla: *"Sesión cerrada: Credenciales cifradas y almacén SQLite purgados (Normativa LOPDP)."*
3. Navegar nuevamente al Catálogo: evidenciar que la base de datos local y la caché quedaron completamente vacías, demostrando el ejercicio de los derechos de supresión y minimización de la LOPDP de Ecuador.
4. Concluir mencionando el enlace al repositorio de GitHub.

---

## 9. Evidencia de Ejecución de Pruebas Automatizadas

```bash
$ flutter test
00:00 +0: loading test/persistencia_test.dart
00:00 +0: Pruebas Unitarias - Persistencia Local y Outbox (Semana 12) FichaModel serializa y deserializa campos de sincronización y LWW
00:00 +1: Pruebas Unitarias - Persistencia Local y Outbox (Semana 12) OperacionPendienteModel calcula backoff exponencial creciente
00:00 +2: Pruebas Unitarias - Persistencia Local y Outbox (Semana 12) SQLite en memoria: Flujo completo de escritura offline, cola Outbox y reconciliación LWW
00:01 +3: test/widget_test.dart: Smoke test de inicialización de la aplicación FichaAI
00:03 +4: All tests passed!
```

---
*Documento preparado conforme a los Criterios de Evaluación del Taller Práctico – Semana 12.*
