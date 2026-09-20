# Quiz App — aprender Flutter por etapas

App Android de preguntas aleatorias con Open Trivia DB. La interfaz está en inglés y las explicaciones del proyecto, en español.

## Estado actual

**Flujo completo implementado.** Categorías → dificultad → partida de diez preguntas → resultados y revisión. Incluye reintentos, protección contra solicitudes duplicadas, intervalo mínimo de cinco segundos entre consultas y confirmación antes de abandonar una partida.

`flutter analyze` no reporta problemas y las **44 pruebas** de modelos, servicio, estado e interfaz pasaron. Una prueba de integración en Android 15 con el API real completó una partida con 9/10, revisó respuestas, reinició la partida y confirmó su abandono. Las capturas están en `build/screenshots/`.

Entorno verificado: Flutter 3.47.5 y Dart 3.13.4 en `C:\Users\David\.nuget\flutter`, Android Studio en `D:\Program Files\Android\Android Studio` y SDK Android en `C:\Users\David\AppData\Local\Android\Sdk`. Las herramientas Android y las licencias están completas. El emulador Android 15 (API 35) está disponible como `emulator-5554`; otra conexión, `emulator-5562`, aparece offline y no se usa. La terminal del agente todavía necesita la ruta absoluta a Flutter porque conserva un PATH anterior a la instalación.

## Ejecutar la app

Abre el emulador desde Device Manager en Android Studio. En una terminal PowerShell nueva:

```powershell
Set-Location 'C:\Users\David\Desktop\quiz-app'
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Si `flutter devices` muestra otro identificador Android, úsalo en lugar de `emulator-5554`. Debes ver una barra morada con “Quiz App”, un indicador de carga y después las categorías reales. Si la conexión falla, aparece un mensaje con “Try again”.

Si la terminal no reconoce `flutter`, puedes usar su ruta completa, por ejemplo:

```powershell
& 'C:\Users\David\.nuget\flutter\bin\flutter.bat' run -d emulator-5554
```

El operador `&` ejecuta un comando cuya ruta está escrita entre comillas en PowerShell. En una terminal que ya reconoce Flutter, basta con `flutter`.

`flutter create --empty --platforms=android --project-name=quiz_app .` ya se ejecutó para generar la estructura Android conservando nuestra pantalla. No necesitas repetirlo. El nombre del paquete Dart usa guion bajo (`quiz_app`), aunque la carpeta use un guion (`quiz-app`).

## Estructura del proyecto

- `lib/main.dart`: punto de entrada, tema y pantalla inicial.
- `lib/models/`: categorías, dificultades, preguntas y resultados inmutables.
- `lib/state/`: reglas y estado de la partida con `QuizSession` y `ChangeNotifier`.
- `lib/services/`: acceso HTTP a Open Trivia DB y manejo de errores.
- `lib/screens/`: categorías, dificultad, partida y resultados; bienvenida conservada como ejemplo.
- `lib/widgets/`: tarjetas reutilizables para categorías y opciones de respuesta.
- `lib/theme/`: tema morado compartido.
- `test/`: pruebas de modelos, servicio, estado y pantallas con HTTP simulado.
- `integration_test/`: recorrido completo en Android con el API real.
- `test_driver/`: captura de imágenes durante la prueba de integración.
- `docs/`: explicaciones y ejercicios para repasar el código.
- `pubspec.yaml`: configuración y dependencias declaradas.
- `pubspec.lock`: versiones exactas resueltas; conservar en Git.
- `android/`: configuración nativa generada para compilar y arrancar en Android.
- `analysis_options.yaml`: reglas del analizador.
- `.dart_tool/` y `build/`: archivos generados y cachés, excluidos de Git.

`android/local.properties` contiene rutas de esta máquina y también se excluye de Git.

## Qué estudiar primero

Empieza por [la guía del flujo completo](docs/03-flujo-completo.md): explica navegación, Dart, consultas HTTP, estado, puntuación, resultados y pruebas, con un orden sugerido para leer el código. [La guía de la etapa 2](docs/02-categorias-y-api.md) explica JSON → modelo → pantalla. [La guía de la etapa 1](docs/01-primeros-pasos.md) conserva la explicación de la bienvenida, ahora ubicada en `lib/screens/welcome_screen.dart`.

## Ruta de aprendizaje

1. Entorno, primera ejecución, widgets y hot reload. **Completada.**
2. Categorías, tema visual, HTTP, JSON y asincronía. **Completada.**
3. Navegación y elección de dificultad. **Completada.**
4. Preguntas, respuestas y estado con `ChangeNotifier`. **Completada.**
5. Resultados y revisión. **Completada.**
6. Pruebas y APK debug. **Completada.**

Las etapas restantes se implementaron juntas por tu indicación; las guías permiten repasarlas ahora en orden.

## Validación de la etapa 1

- `flutter analyze`: sin problemas.
- `flutter run -d emulator-5554`: APK debug compilado, instalado y ejecutado en Android 15.
- Captura revisada: `build/first-run.png`, con la bienvenida visible sin desbordamientos.
- Tecla `r`: hot reload completado. No se cambió el código durante esa comprobación; el ejercicio de la guía permite practicar con un cambio visible.
- La sesión del agente se desconectó con `d`, dejando la app abierta en el emulador. Para practicar hot reload, inicia tu propia sesión con `flutter run`.

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk` y se actualiza con cada compilación. La versión final contiene el flujo completo.

## Validación de la etapa 2

- `flutter analyze`: sin problemas.
- `flutter test`: 22 pruebas aprobadas, incluyendo errores de red, JSON inválido, timeout, solicitudes duplicadas, espera entre reintentos y nombres largos con texto ampliado.
- `flutter run -d emulator-5554`: APK debug compilado e instalado; categorías obtenidas desde Open Trivia DB en Android 15.
- Captura revisada: `build/categories-stage-2.png`.
- Sesión desconectada con `d`, dejando la app abierta. Para hacer hot reload, inicia tu propia sesión con `flutter run`.

## Comportamiento implementado

- Todas las categorías de [Open Trivia DB](https://opentdb.com/api_config.php).
- Tres quizzes por categoría: Easy, Medium y Hard; 10 preguntas de opción múltiple.
- Seleccionar resalta una respuesta. Next la confirma, suma un punto si es correcta y avanza inmediatamente.
- Previous consulta preguntas confirmadas sin modificar respuestas ni duplicar puntos.
- Finish contabiliza la última respuesta y abre el resumen con revisión.
- Resultados con Play Again y Back to Categories.
- Sin login, temporizador, historial, backend propio, modo offline ni tokens de sesión. El estado vive en memoria.

Open Trivia DB no requiere una clave de API. No usamos sus tokens opcionales de sesión, por lo que una pregunta puede repetirse entre partidas. Los resultados incluyen atribución y enlace a la licencia CC BY-SA 4.0.

## Repetir la validación final

```powershell
flutter analyze
flutter test
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/quiz_live_test.dart -d emulator-5554
flutter build apk --debug -t lib/main.dart
```

Las 44 pruebas normales usan respuestas simuladas, incluyendo errores del API y textos largos con tamaño de letra ampliado. La integración requiere Internet, el API disponible y un emulador conectado. Después de ejecutarla, el último comando vuelve a generar el APK normal desde `lib/main.dart`.
