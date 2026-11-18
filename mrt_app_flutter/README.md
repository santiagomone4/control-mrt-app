# Control MRT — App Android Offline

App móvil para **relevamiento, procesamiento, diseño y control de obra de Micro-embalses de Retención Temporaria (MRT)**.

## Características

- 100% offline (sin internet requerido en campo)
- Modo Nivel Óptico: puntos de Base y Coronamiento por separado
- Modo GNSS/SurvX: importación de .xlsx con parser automático
- Perfil longitudinal interactivo con zonas de corte/relleno
- Exportación PDF, Excel y .json
- Compartir por WhatsApp / Drive / Email

## Paleta de colores

| Color | Hex | Uso |
|-------|-----|-----|
| Autoridad & Confianza | `#112B4F` | AppBar, botones primarios, coronamiento |
| Agua & Precisión | `#4C9F55` | Verde, OK, relleno |
| Suelo & Base | `#F3F1EC` | Fondo, tierra |
| Datos & Estructura | `#3E4144` | Texto, ejes |
| Steel Blue | `#5BACC3` | Secundario, tabs, agua |

## Tipografía

- **IBM Plex Sans** — Encabezados, botones, KPIs, tablas
- **Roboto** — Cuerpo, formularios, descripciones

## Compilar el APK (GitHub Actions — automático)

1. Crear repositorio en GitHub
2. Subir esta carpeta `mrt_app_flutter/` al repositorio
3. Ir a **Actions** → el workflow se dispara solo
4. Descargar **Control_MRT_Release_APK** cuando finalice (~5 min)

## Compilar localmente

```bash
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

Requiere Flutter SDK 3.24+ y Android SDK 34.
