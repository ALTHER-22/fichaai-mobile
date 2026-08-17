# FichaAI - Aplicación Móvil

Este repositorio contiene el código fuente de la aplicación móvil del proyecto **FichaAI** construida en Flutter, así como la documentación técnica para la configuración del entorno de desarrollo.

## Entorno de Desarrollo Móvil

Para el desarrollo del cliente móvil se seleccionó el framework **Flutter** debido a su capacidad de generar aplicaciones compiladas nativamente para múltiples plataformas desde una única base de código, garantizando alto rendimiento y control total sobre los píxeles de la interfaz.

### Versiones Instaladas

- **Flutter SDK**: 3.47.0 (Stable)
- **Dart SDK**: 3.13.0
- **Android Studio**: Última versión estable
- **Android SDK**: API Level 36 (Tiramisu/UpsideDownCake)

### Pasos de Configuración y Ejecución (Reproducible)

1. **Configuración del Entorno Móvil (Flutter):**
   - Descargar e instalar el Flutter SDK y agregarlo al PATH.
   - Instalar Android Studio y configurar un dispositivo virtual (AVD) o conectar un dispositivo físico mediante depuración USB.
   - Aceptar las licencias nativas ejecutando: `flutter doctor --android-licenses`

2. **Ejecutar comando de diagnóstico:**
   Para verificar que no existen hallazgos pendientes en el entorno, ejecutar:
   ```bash
   flutter doctor -v
   ```
   *(Todos los checks principales de Flutter, Android Toolchain y el editor deben tener un check verde).*

3. **Variables de Entorno y Direccionamiento (Frontend):**
   Para conectar la aplicación con el backend local sin cifrar (exclusivo para desarrollo), se utiliza la URL base configurada dinámicamente:
   - **Emulador Android**: Utilizar `http://10.0.2.2:5000/api`
   - **Dispositivo Físico**: Utilizar `http://<IP-LOCAL-PC>:5000/api`

4. **Lanzar la Aplicación Móvil:**
   Dentro del directorio del proyecto Flutter, ejecutar:
   ```bash
   flutter run
   ```
   *La recarga en caliente (Hot Reload) está operativa pulsando la tecla `r` en la terminal o guardando archivos en el IDE soportado (VS Code/Android Studio).*
