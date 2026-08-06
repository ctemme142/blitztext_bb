# Blitztext iOS

Die iOS-App ist auf iOS 26 und iPhone-only ausgerichtet. Das Xcode-Projekt wird
aus `project.yml` mit XcodeGen erzeugt.

## In Xcode öffnen

```sh
cd /Users/ctemme/codex/blitztext-app/apps/ios
xcodegen generate
open BlitztextIOS.xcodeproj
```

In Xcode anschließend das eigene Apple-Entwicklerteam auswählen, das iPhone
17 Pro Max als Zielgerät wählen und die App mit Run installieren.

Beim ersten Start werden Mikrofonzugriff und der persönliche OpenAI-API-Key
abgefragt. Die Transkription erfolgt in dieser ersten Version online; der Key
wird ausschließlich im iOS-Schlüsselbund gespeichert.
