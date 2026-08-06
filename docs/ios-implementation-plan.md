# Blitztext iOS: Umsetzungsplan

Dieser Plan beschreibt die erste Umsetzung der iOS-Variante von Blitztext. Ziel ist eine eigenständige iOS-App mit derselben fachlichen Identität wie die macOS-App, aber mit einem Bedienmodell, das zu iPhone und iPad passt.

Die iOS-App wird nicht als Kopie der Menüleisten-App behandelt. Gemeinsame Produktregeln werden übernommen; Betriebssystem- und Bedienkonzepte bleiben plattformspezifisch.

## 1. Zielbild

Die erste iOS-Version soll diesen Kernablauf zuverlässig ermöglichen:

```text
App öffnen -> Workflow auswählen -> Aufnahme starten -> Aufnahme beenden
-> Sprache transkribieren -> optional umformulieren -> Ergebnis prüfen
-> kopieren, teilen oder innerhalb der App weiterverwenden
```

Der erste Release muss nicht versuchen, das macOS-Verhalten vollständig nachzubauen. Insbesondere sind systemweite globale Tastenkürzel, ein dauerhaftes Tray-Menü und automatisches Einfügen in beliebige andere Apps auf iOS nicht die Grundlage des ersten Produkts.

## 2. Festgelegter Umfang für Version 1

### Enthalten

- iPhone- und iPad-App mit Swift und SwiftUI.
- Manuelle Sprachaufnahme mit klaren Zuständen: bereit, Aufnahme, Verarbeitung, Ergebnis, Fehler.
- Online-Transkription über den bestehenden OpenAI-Workflow.
- Die vier vorhandenen Workflows:
  - Blitztext
  - Blitztext+
  - Blitztext $%&!
  - Blitztext :)
- Ergebnisanzeige mit Bearbeiten, Kopieren und Teilen.
- Verwaltung des OpenAI-Schlüssels über den iOS-Keychain.
- Einstellungen für Sprache, Workflow und relevante Anpassungen.
- Datenschutz- und Fehlerhinweise passend zu iOS.
- Tests für den fachlichen Ablauf und die wichtigsten UI-Zustände.

### Bewusst später

- Systemweite Diktierfunktion in anderen Apps.
- Vollständige Share-Extension.
- iOS-Widget oder Control-Center-Integration.
- Hintergrundaufnahme.
- Lokale Transkription auf dem Gerät.
- Synchronisation zwischen Geräten.
- Benutzerkonto oder eigener Blitztext-Server.

Diese Punkte können später ergänzt werden, sollen aber die erste funktionierende iOS-Version nicht verzögern.

## 3. Phase 0: Produktentscheidungen festhalten

### Schritt 0.1: iOS-Bedienmodell bestätigen

Vor dem ersten Code wird verbindlich festgelegt:

- Die App startet mit einer eigenen Aufnahmeansicht.
- Das Ergebnis bleibt zunächst innerhalb von Blitztext.
- Der Nutzer kann das Ergebnis kopieren oder über das iOS-Share-Sheet weitergeben.
- Eine Aufnahme wird über einen sichtbaren Start-/Stopp-Befehl gesteuert.
- Während der Verarbeitung wird keine zweite Aufnahme gestartet.

**Abnahmekriterium:** Die gewünschte iOS-Nutzung lässt sich in einem kurzen Ablauf beschreiben, ohne auf macOS-Menüleiste oder globale Tastenkürzel zu verweisen.

### Schritt 0.2: Datenschutzmodus definieren

Für die erste Version wird zwischen zwei klaren Zuständen unterschieden:

- Online-Modus: Audiodaten werden zur Transkription an OpenAI gesendet; Umformulierung ebenfalls über OpenAI.
- Lokaler Modus: bleibt als späterer Ausbau gekennzeichnet, bis ein belastbarer iOS-Whisper/Core-ML-Weg getestet ist.

Die App darf keinen scheinbar lokalen Modus anbieten, solange die komplette Verarbeitung nicht tatsächlich lokal erfolgt.

**Abnahmekriterium:** Jede Verarbeitung zeigt oder dokumentiert eindeutig, ob Daten das Gerät verlassen.

### Schritt 0.3: Gemeinsame Produktverträge definieren

Aus den vorhandenen macOS-Workflows werden plattformunabhängige Beschreibungen abgeleitet:

- Workflow-ID.
- Anzeigename und Beschreibung.
- Eingabeart.
- Transkriptionsschritt.
- Optionaler Textverarbeitungsschritt.
- Erwartetes Ergebnisformat.
- Fehler- und Abbruchverhalten.

Die Verträge sollten zunächst als dokumentierte JSON-Struktur oder als kleine, testbare Swift-Modelle in `shared/` festgehalten werden. Die iOS-App darf nicht durch Kopieren der macOS-Workflowdateien gestartet werden.

**Abnahmekriterium:** Jeder bestehende Workflow ist eindeutig beschrieben und kann anhand derselben Eingabe-/Erwartungsdaten auf mehreren Plattformen getestet werden.

## 4. Phase 1: iOS-Projektgrundlage

### Schritt 1.1: Zielumgebung festlegen

- Mindestversion von iOS festlegen.
- Xcode-Version und Swift-Version an die vorhandene macOS-Entwicklung anpassen.
- Entscheiden, ob das Projekt zunächst mit einer separaten `project.yml` für XcodeGen oder direkt als Xcode-Projekt entsteht.
- Bundle Identifier für iOS reservieren, zum Beispiel `app.blitztext.ios`.
- Gemeinsame Versions- und Buildnummern dokumentieren.

Die Mindestversion soll nur so hoch sein, wie es für Audioaufnahme, SwiftUI, Keychain und Share-Sheet wirklich erforderlich ist.

### Schritt 1.2: Ordnerstruktur anlegen

Vorgesehene Struktur:

```text
apps/
  ios/
    App/
    Features/
    Services/
    Views/
    Resources/
shared/
  product/
  workflows/
  prompts/
  api-contracts/
  settings/
  test-fixtures/
```

Die bestehende `BlitztextMac/`-Struktur bleibt in dieser Phase unverändert. Ein späteres Verschieben nach `apps/mac/` ist eine eigene Aufräumaufgabe und gehört nicht in den ersten iOS-Meilenstein.

### Schritt 1.3: App-Shell bauen

- SwiftUI-App-Entry-Point.
- Navigation für Aufnahme, Verlauf/Ergebnisse und Einstellungen.
- Unterstützung für iPhone und iPad mit adaptiver Breite.
- App-Icon und grundlegende Farben/Typografie aus der bestehenden Marke ableiten.
- Keine macOS-spezifischen Services in die iOS-App übernehmen, wenn sie dort keine Entsprechung haben.

**Abnahmekriterium:** Die App startet auf einem Simulator und einem Testgerät, navigiert ohne Platzhalterfehler und zeigt für jede Hauptfunktion einen definierten Zustand.

## 5. Phase 2: Audioaufnahme

### Schritt 2.1: Audio-Service kapseln

Einen iOS-spezifischen Audio-Service auf Basis von `AVAudioSession` und `AVAudioRecorder` oder einer passenden AVFoundation-Aufnahmekette erstellen.

Der Service soll nur Plattformaufgaben übernehmen:

- Mikrofonberechtigung anfordern.
- Audio-Session konfigurieren.
- Aufnahme starten und stoppen.
- Temporäre Audiodatei verwalten.
- Dauer und Aufnahmefehler liefern.
- Ressourcen nach Erfolg, Abbruch oder Fehler sicher freigeben.

### Schritt 2.2: Aufnahmestatus modellieren

Ein explizites Zustandsmodell verhindert widersprüchliche UI-Aktionen:

```text
idle -> requestingPermission -> recording -> preparingUpload
-> transcribing -> processingWorkflow -> showingResult
```

Zusätzlich müssen Abbruch, fehlende Berechtigung, zu kurze Aufnahme, Netzwerkfehler und App-Unterbrechungen modelliert werden.

### Schritt 2.3: Aufnahme-UI umsetzen

- Große, eindeutige Start-/Stopp-Aktion.
- Sichtbarer Aufnahmeindikator und verstrichene Zeit.
- Abbrechen ohne Ergebnisübernahme.
- Erklärung bei fehlender Mikrofonberechtigung mit Link zu den iOS-Einstellungen.
- Rücksicht auf Telefonanrufe, Audio-Unterbrechungen und App-Wechsel.

**Abnahmekriterium:** Eine Aufnahme kann gestartet, gestoppt, verworfen und wiederholt werden, ohne dass temporäre Dateien oder blockierte Audio-Sessions zurückbleiben.

## 6. Phase 3: Transkription und Workflows

### Schritt 3.1: Gemeinsame API-Verträge nutzen

Die iOS-App erhält eine eigene Netzwerk- und Transkriptionsschicht, die sich an den gemeinsamen Verträgen orientiert. Die macOS-Services werden nicht blind importiert, weil deren Fehler- und Dateipfade macOS-spezifisch sind.

Zu dokumentieren und zu testen sind:

- Audio-Upload und Format.
- Transkriptionsantwort.
- Textverarbeitungsanfrage.
- Textverarbeitungsantwort.
- Abbruch und Timeout.
- Rate-Limit- und Authentifizierungsfehler.
- Verhalten bei fehlender Netzwerkverbindung.

### Schritt 3.2: API-Schlüssel sicher speichern

- Schlüssel ausschließlich im iOS-Keychain speichern.
- Keine Schlüssel in UserDefaults, Logs, Crash-Meldungen oder Test-Fixtures ablegen.
- Erstmalige Einrichtung in einem verständlichen Einstellungsbildschirm ermöglichen.
- Schlüssel löschen und ersetzen können.
- Netzwerk- und Datenschutzstatus verständlich anzeigen.

### Schritt 3.3: Workflows implementieren

Die vier Workflows werden als fachliche Operationen ausgeführt:

1. Audio transkribieren.
2. Bei Blitztext das Ergebnis direkt anzeigen.
3. Bei Blitztext+, Blitztext $%&! und Blitztext :) die Textverarbeitung ausführen.
4. Das Ergebnis mit Workflowname und Zeitstempel anzeigen.

Die UI soll nicht voraussetzen, dass alle Workflows dieselbe Laufzeit oder denselben Fehlerpfad haben.

**Abnahmekriterium:** Jeder Workflow kann mit einer aufgezeichneten Testdatei oder einem gemockten Transkript ausgeführt werden und liefert ein Ergebnis im definierten Vertrag.

## 7. Phase 4: Ergebnis, Teilen und Wiederverwenden

### Schritt 4.1: Ergebnisansicht

Die Ergebnisansicht enthält:

- fertig verarbeiteten Text;
- Workflow und Zeitstempel;
- Bearbeiten;
- Kopieren;
- Teilen;
- erneut ausführen oder neue Aufnahme starten;
- verständliche Anzeige von Teilfehlern, etwa erfolgreiche Transkription aber fehlgeschlagene Umformulierung.

### Schritt 4.2: iOS-Integration

- `UIPasteboard` für Kopieren verwenden.
- Native Share-Sheet-Integration verwenden.
- Keine automatische Einfügung in fremde Apps versprechen.
- Optionalen App-internen Verlauf erst hinzufügen, wenn Speicher- und Löschkonzept feststehen.

**Abnahmekriterium:** Der Nutzer kann das Ergebnis ohne Umweg in eine andere App übertragen und erkennt jederzeit, ob der Text nur kopiert oder tatsächlich geteilt wurde.

## 8. Phase 5: Einstellungen und Datenschutz

### Schritt 5.1: Einstellungen portieren

Nur Einstellungen übernehmen, die auf iOS sinnvoll sind:

- Sprache.
- Standard-Workflow.
- OpenAI-Schlüssel.
- sichere/online Verarbeitung, sobald beide Modi existieren.
- benutzerdefinierte Workflowtexte oder Begriffe, falls deren Schema vorher definiert wurde.

macOS-spezifische Einstellungen wie Autostart, Accessibility oder globale Hotkeys werden nicht angezeigt.

### Schritt 5.2: Datenschutzoberfläche

- Mikrofonzugriff erklären.
- Online-Verarbeitung vor der ersten Nutzung verständlich benennen.
- Link auf die vorhandene Datenschutzdokumentation ergänzen.
- Fehler- und Diagnoseprotokolle standardmäßig ohne Audio und ohne vollständige Transkripte führen.
- Temporäre Audiodateien nach erfolgreicher Verarbeitung oder Abbruch löschen.

**Abnahmekriterium:** Ein Nutzer kann vor der ersten Aufnahme nachvollziehen, welche Daten verarbeitet werden und wohin sie gesendet werden.

## 9. Phase 6: Tests und Qualitätssicherung

### Schritt 6.1: Unit-Tests

- Workflow-Auswahl.
- Zustandsübergänge der Aufnahme und Verarbeitung.
- Dekodierung von API-Antworten.
- Fehler-Mapping.
- Einstellungen und Keychain-Abstraktion mit Testimplementierung.
- Temporäre Audiodatei-Lebensdauer.

### Schritt 6.2: Integrationstests

- Aufnahme bis zur Transkription mit gemocktem Netzwerk.
- Transkription plus Textverarbeitung für alle vier Workflows.
- Netzwerkausfall nach der Aufnahme.
- ungültiger API-Schlüssel.
- Mikrofonberechtigung verweigert.
- Audio-Unterbrechung durch Anruf oder andere App.

### Schritt 6.3: UI- und Gerätetests

Auf mindestens einem iPhone und einem iPad prüfen:

- Hoch- und Querformat, soweit unterstützt.
- kleine und große Displays.
- Dynamic Type und VoiceOver-Grundabläufe.
- dunkler und heller Modus.
- langsame Netzwerkverbindung.
- App-Wechsel während Aufnahme und Verarbeitung.
- niedriger Akkustand und fehlender Speicherplatz als Fehlerfälle, soweit testbar.

**Abnahmekriterium:** Der Kernablauf funktioniert reproduzierbar auf einem realen iPhone; Simulatoren werden für UI- und Netzwerk-Mocks ergänzend verwendet.

## 10. Phase 7: TestFlight und Release-Vorbereitung

### Schritt 7.1: Signierung und App-Konfiguration

- Apple Developer Team konfigurieren.
- Bundle Identifier und App Capabilities festlegen.
- Mikrofon-Nutzungstext in `Info.plist` prüfen.
- App-Icon, Launch-Screens und Versionsnummern vervollständigen.
- Datenschutzangaben für den App-Store vorbereiten.

### Schritt 7.2: Interner TestFlight-Build

- Archivierten Build auf einem echten Gerät installieren.
- Erstinstallation, Upgrade und Deinstallation prüfen.
- API-Schlüssel-Einrichtung prüfen.
- Crash- und Fehlerberichte ohne sensible Inhalte prüfen.
- Eine kleine Gruppe mit klaren Testaufgaben durch den Kernablauf führen lassen.

### Schritt 7.3: Release-Gate

Der erste iOS-Build gilt erst als bereit, wenn:

- alle vier Workflows funktionieren;
- Online-Datenfluss dokumentiert ist;
- Schlüssel nicht im Klartext außerhalb des Keychain auftauchen;
- temporäre Audiodaten zuverlässig entfernt werden;
- Kopieren und Teilen auf iPhone und iPad funktionieren;
- Berechtigungs-, Offline- und Authentifizierungsfehler verständlich sind;
- macOS-Build und bestehende macOS-Funktionalität weiterhin unverändert funktionieren.

## 11. Empfohlene Reihenfolge der konkreten Arbeitspakete

1. iOS-Bedienmodell und Datenschutzgrenzen bestätigen.
2. Gemeinsame Workflow- und API-Verträge dokumentieren.
3. iOS-Projekt und App-Shell anlegen.
4. Mikrofonberechtigung und Audioaufnahme implementieren.
5. Aufnahmezustände und Fehlerzustände testen.
6. Keychain-Speicherung und Einstellungsansicht implementieren.
7. Transkriptionsservice mit gemocktem Netzwerk anbinden.
8. Blitztext-Workflow end-to-end fertigstellen.
9. Die drei Textverarbeitungs-Workflows ergänzen.
10. Ergebnisansicht, Kopieren und Share-Sheet ergänzen.
11. Datenschutzanzeige und temporäre Dateilöschung prüfen.
12. Unit-, Integrations- und UI-Tests vervollständigen.
13. Auf realem iPhone und iPad testen.
14. TestFlight-Build erstellen und internes Feedback einarbeiten.
15. Erst danach lokale Transkription, Share-Extension oder Synchronisation bewerten.

## 12. Risiken und Entscheidungen, die später bewusst getroffen werden müssen

### Lokale Transkription

Die vorhandene WhisperKit/CoreML-Integration ist ein guter Ausgangspunkt, aber iOS bringt andere Speicher-, Akku- und Hintergrundbedingungen mit. Ein iOS-Modell wird erst nach einem Geräteexperiment verbindlich eingeplant.

### Gemeinsamer Swift-Code

Gemeinsamer Swift-Code ist sinnvoll für fachliche Modelle, Workflow-Verträge und API-Datentypen. Audio, Keychain, Berechtigungen, Dateipfade und UI bleiben zunächst in den jeweiligen Apps. Gemeinsamer Code wird nur eingeführt, wenn er tatsächlich dieselbe Bedeutung und dieselben Tests hat.

### Automatisches Einfügen

Die macOS-App kann mit Accessibility in andere Apps einfügen. iOS bietet dafür kein gleichwertiges allgemeines Modell. Copy, Share-Sheet und später eine Share-Extension sind die realistischen Produktpfade.

### Server oder direkter API-Zugriff

Die bestehende App verwendet einen direkten API-Zugriff mit eigenem Schlüssel. Für eine öffentliche iOS-App muss später geprüft werden, ob dieses Modell aus Sicherheits-, Kosten- und App-Store-Sicht beibehalten werden kann. Diese Entscheidung wird vor einem öffentlichen Release dokumentiert und nicht stillschweigend geändert.

## 13. Ergebnis dieses Plans

Der erste iOS-Meilenstein ist eine native SwiftUI-App, die Sprache aufnimmt, über den dokumentierten Online-Weg verarbeitet, alle vier Blitztext-Workflows ausführt und das Ergebnis zuverlässig kopieren oder teilen lässt. Sie bildet die gemeinsame Produktbasis für spätere iOS-Erweiterungen, ohne die macOS-App zu destabilisieren oder die Einschränkungen von iOS zu verschleiern.
