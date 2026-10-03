# 📱 FichaAI - Aplicación Móvil Android

[![Flutter](https://img.shields.io/badge/Flutter-3.47.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.0-0175C2?logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Plataforma-Android%20%28Tablet%20%2F%20Móvil%29-3DDC84?logo=android)](https://developer.android.com)
[![Backend Live](https://img.shields.io/badge/Backend-Render%20Cloud%20Active-brightgreen)](https://fichaai-backend.onrender.com/api/health)
[![Release](https://img.shields.io/badge/Release-v1.0.0%20Oficial-blue)](https://github.com/ALTHER-22/fichaai-mobile/releases/tag/v1.0.0)

**FichaAI Mobile** es el cliente oficial para Android del sistema inteligente de generación y consulta de fichas técnicas oficiales de smartphones, impulsado por **Google Gemini AI** y respaldado por el catálogo en tiempo real de **GSMArena** (>6,000 modelos de teléfonos).

---

## 📥 Descarga e Instalación Directa (Para Evaluación)

Para probar la aplicación directamente en cualquier **teléfono o tablet Android**:

### 📲 [👉 **DESCARGAR APK OFICIAL (v1.0.0)** 👈](https://github.com/ALTHER-22/fichaai-mobile/releases/download/v1.0.0/app-release.apk)

> **Instrucciones rápidas para el dispositivo:**
> 1. Abre el enlace anterior desde el navegador del dispositivo Android (o tablet).
> 2. Una vez descargado el archivo `app-release.apk`, pulsa sobre la notificación de descarga o búscalo en la carpeta *Descargas*.
> 3. Si el sistema solicita confirmación, selecciona **"Permitir instalar aplicaciones de fuentes desconocidas"** para ese navegador.
> 4. Pulsa **Instalar** y abre **FichaAI**.

---

## 🚀 Funcionalidades Principales

- **Buscador Inteligente con IA:** Extrae automáticamente la ficha técnica oficial con solo escribir el nombre o modelo comercial.
- **Galería Oficial HD Multi-Ángulo:** Renders de estudio en alta resolución (700px - 1024px) extraídos directamente del catálogo oficial.
- **Precios MSRP Oficiales:** Cálculo del precio oficial de lanzamiento global unificado en **USD ($)**.
- **Arquitectura Offline-First:** Arranque ultrarrápido sin pantallas de bloqueo y sincronización bidireccional asíncrona con el backend en la nube.
- **Modelos de Prueba Sugeridos:**
  - `Honor Magic 8 Lite`
  - `Tecno Spark 20 Pro Plus`
  - `Samsung Galaxy A55 5G`
  - `Xiaomi 14 Ultra`
  - `iPhone 16 Pro`

---

## 🌐 Conexión con el Backend en la Nube

La aplicación móvil ya está compilada y enlazada de forma nativa con el servidor de producción:
- **API URL Base:** `https://fichaai-backend.onrender.com/api`
- **Estado de Servicio (Health Check):** `https://fichaai-backend.onrender.com/api/health`

---

## 🛠️ Entorno de Desarrollo y Compilación Local

### Versiones del Entorno
- **Flutter SDK:** 3.47.0 (Stable)
- **Dart SDK:** 3.13.0
- **Android Gradle Plugin / Kotlin:** Gradle 9.3+ compatible
- **Target SDK:** Android API Level 36 (Android 14+)

### Ejecución en Modo Desarrollo
```bash
# Obtener dependencias
flutter pub get

# Ejecutar conectando a producción
flutter run --dart-define=AMBIENTE=prod --dart-define=API_URL=https://fichaai-backend.onrender.com/api
```
