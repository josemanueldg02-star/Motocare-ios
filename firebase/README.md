# Seguridad de Firestore — MotoCare

Reglas de seguridad de Cloud Firestore y sus tests automatizados.

Las reglas son **la línea de defensa principal** de la app: la "API key" de Firebase
que viaja en `GoogleService-Info.plist` no es un secreto, así que cualquiera puede
hablar con tu proyecto. Lo que impide que un atacante lea o modifique los datos de
otros usuarios son estas reglas, no la app.

## Archivos

| Archivo | Qué es |
|---|---|
| `firestore.rules` | Las reglas. Cada usuario solo accede a `users/{su-uid}`; el resto, denegado. |
| `firebase.json` | Configuración del emulador. |
| `tests/firestore.test.js` | Tests de las reglas (aislamiento entre usuarios, acceso anónimo, suplantación de uid, etc.). |

## Requisitos (instalar una sola vez)

No hace falta tocar producción: todo corre en el **emulador** local.

```bash
# 1. Node.js (incluye npm). Con Homebrew:
brew install node

# 2. Java 21+ (lo exige la Firebase CLI / el emulador de Firestore):
brew install openjdk@21
# openjdk@21 queda "keg-only". Para que la CLI lo encuentre, o bien lo añades al PATH:
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
# o lo enlazas para los wrappers del sistema:
sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk \
  /Library/Java/JavaVirtualMachines/openjdk-21.jdk

# 3. Firebase CLI:
npm install -g firebase-tools
```

## Ejecutar los tests

```bash
cd firebase
npm install        # instala las dependencias de test (solo la primera vez)
npm test           # arranca el emulador, corre los tests y lo apaga
```

Un `demo-` como id de proyecto hace que el emulador funcione 100 % offline, sin
credenciales ni conexión a tu Firebase real.

## Desplegar las reglas a producción

Cuando los tests pasen y quieras aplicar estas reglas a tu proyecto real:

```bash
firebase login
firebase use --add            # elige tu proyecto real de Firebase
firebase deploy --only firestore:rules
```

> Hazlo solo cuando los tests estén en verde. Unas reglas mal desplegadas pueden
> dejar fuera a usuarios legítimos o, peor, abrir el acceso.
