# Blitztext iOS: Festgelegte Produktentscheidungen

Dieses Dokument sammelt die im Gespräch bestätigten Entscheidungen für die erste iOS-Version von Blitztext. Es dient als verbindliche Produktgrundlage für die Umsetzung.

## 1. Zielplattform

- Zielgerät der ersten Version: iPhone.
- Referenzgerät: iPhone 17 Pro Max.
- Unterstützte iOS-Version: iOS 26.
- Die erste Version wird nicht für iPad entwickelt.
- Die App arbeitet zunächst ausschließlich im Hochformat.
- Der helle oder dunkle Darstellungsmodus wird automatisch vom iPhone übernommen.
- Größere Schrift und grundlegende VoiceOver-Bedienung werden berücksichtigt.

## 2. Installation während der Entwicklung

- Die erste Version wird direkt über Xcode auf dem iPhone installiert.
- TestFlight und App Store sind zunächst nicht erforderlich.
- Der Apple-Account wird in Xcode unter `Xcode -> Settings -> Accounts` hinterlegt.
- Die Geräteeinrichtung und Verbindung mit Xcode erfolgen erst, wenn ein erster lauffähiger iOS-Stand vorhanden ist.

## 3. Erster App-Start

Beim ersten Öffnen erscheint ein kurzer Einrichtungsablauf:

1. Mikrofonzugriff erlauben.
2. OpenAI-API-Schlüssel eingeben.
3. API-Schlüssel und Verbindung testen.
4. Bei einem Fehler in der Einrichtung bleiben und eine verständliche Fehlermeldung anzeigen.
5. Bei erfolgreicher Prüfung den ersten Workflow festlegen.
6. Zur Aufnahmeansicht wechseln.

Der erste Standardworkflow ist `Blitztext`, also reine Transkription ohne zusätzliche Textverarbeitung.

## 4. API-Schlüssel und Datenverarbeitung

- Die erste Version verwendet den eigenen OpenAI-API-Schlüssel des Nutzers.
- Der Schlüssel wird ausschließlich im iOS-Keychain gespeichert.
- Der Schlüssel kann in den Einstellungen geändert werden.
- Der Schlüssel kann in den Einstellungen gelöscht werden.
- Vor der allerersten Transkription weist die App ausdrücklich darauf hin, dass die Audioaufnahme an OpenAI gesendet wird.
- Diese Bestätigung wird nicht vor jeder weiteren Aufnahme erneut verlangt.
- Eine lokale Transkription ist in der ersten Version nicht enthalten.
- Lokale Modelle und Core-ML/WhisperKit-Unterstützung bleiben eine spätere Erweiterung.

## 5. Workflows

Die erste iOS-Version enthält die vier festen Workflows aus der macOS-App:

- `Blitztext`: Transkription ohne weitere Textverarbeitung.
- `Blitztext+`: Transkription und anschließende Textverbesserung.
- `Blitztext $%&!`: Transkription und Umformulierung eines emotionalen oder ärgerlichen Textes.
- `Blitztext :)`: Transkription und Ergänzung passender Emojis.

Eigene Workflow-Namen und eigene Workflow-Texte werden in der ersten Version nicht angeboten.

Der aktuelle Workflow ist auf der Aufnahmeansicht immer sichtbar. Er kann innerhalb der App gewechselt werden, aber nicht während einer laufenden Aufnahme.

Nach dem Wechsel wird der neue Workflow als zuletzt verwendeter Workflow gespeichert.

## 6. Start über Aktionstaste und Rückseitentippen

Die App stellt App Shortcuts für die iOS-Systemintegration bereit.

- Beim ersten Start wird Blitztext bewusst geöffnet und eingerichtet.
- Danach kann die Aktionstaste den Blitztext-Shortcut aufrufen.
- „Auf Rückseite tippen“ kann ebenfalls den Blitztext-Shortcut aufrufen.
- Beide Schnellstartwege verwenden den zuletzt ausgewählten Workflow.
- Blitztext kann durch den Shortcut geöffnet oder in den Vordergrund gebracht werden.
- Die Aufnahme beginnt nach dem Start automatisch.
- Die App muss nicht vor jeder Aufnahme manuell geöffnet werden.
- Die App läuft nicht dauerhaft wie eine macOS-Menüleisten-App im Hintergrund.
- Wird die App während einer laufenden Aufnahme erneut über Aktionstaste oder Rückseitentippen ausgelöst, bleibt die laufende Aufnahme unverändert.
- Nach einem abgeschlossenen Ergebnis starten Aktionstaste und Rückseitentippen direkt eine neue Aufnahme mit dem zuletzt verwendeten Workflow.

## 7. Aufnahmeablauf

Der vorgesehene Ablauf lautet:

```text
Aktionstaste oder Rückseitentippen
-> Blitztext öffnet sich
-> zuletzt verwendeten Workflow laden
-> Aufnahme automatisch starten
-> sprechen
-> Aufnahme beenden
-> transkribieren
-> Workflow ausführen
-> Ergebnis anzeigen und kopieren
```

Die Aufnahmeansicht enthält:

- sichtbaren Namen des aktuellen Workflows;
- eindeutigen Aufnahmeindikator;
- verstrichene Aufnahmezeit;
- Button `Aufnahme beenden`;
- separaten Button `Abbrechen`.

Regeln für die Aufnahme:

- Maximale Aufnahmedauer: fünf Minuten.
- Nach fünf Minuten wird die Aufnahme automatisch beendet.
- `Aufnahme beenden` verarbeitet die Aufnahme.
- `Abbrechen` verwirft die Aufnahme ohne Transkription.
- Während der Aufnahme wird der Workflow nicht gewechselt.
- Start und Ende der Aufnahme geben ein kurzes haptisches Signal.
- Aktionstaste und Rückseitentippen werden während der Aufnahme ignoriert.

## 8. Unterbrechungen

Wenn der Nutzer während einer Aufnahme zu einer anderen App wechselt:

- wird die Aufnahme beendet;
- die temporäre Audiodatei bleibt zunächst erhalten;
- Blitztext zeigt eine klare Rückfrage an;
- der Nutzer kann die Aufnahme erneut verarbeiten oder verwerfen.

Bei einem Telefonat oder einer anderen Audio-Unterbrechung gilt dasselbe Verhalten.

Die App nimmt nicht unbemerkt im Hintergrund weiter auf.

## 9. Verarbeitung und Fehler

Bei einem Netzwerk- oder OpenAI-Fehler bleibt die Aufnahme vorübergehend erhalten.

Die App bietet dann:

- `Erneut versuchen`;
- `Aufnahme verwerfen`.

Bei `Aufnahme verwerfen` wird die temporäre Audiodatei sofort gelöscht.

Auch bei folgenden Fällen müssen verständliche Zustände und Hinweise existieren:

- Mikrofonzugriff verweigert;
- API-Schlüssel fehlt;
- API-Schlüssel ungültig;
- keine Internetverbindung;
- OpenAI-Limit oder Serverfehler;
- Audio-Unterbrechung;
- Aufnahme zu kurz;
- fehlgeschlagene Textverarbeitung nach erfolgreicher Transkription.

Wenn die Transkription erfolgreich war, aber ein erweiterter Workflow bei der Textverarbeitung scheitert, darf das Rohtranskript nicht verloren gehen.

## 10. Ergebnisansicht

Nach erfolgreicher Verarbeitung:

- wird das fertige Ergebnis angezeigt;
- wird der fertige Text automatisch in die Zwischenablage kopiert;
- wird ausschließlich der Text kopiert, ohne Workflowname, Zeitstempel oder zusätzliche Hinweise;
- kann der Text innerhalb von Blitztext bearbeitet werden;
- aktualisiert ein Button `Kopieren` die Zwischenablage nach einer Bearbeitung;
- kann das Rohtranskript optional über `Original anzeigen` eingeblendet werden;
- bleibt das Ergebnis sichtbar, bis der Nutzer `Fertig` oder `Neue Aufnahme` auswählt.

Die Schaltfläche `Fertig` entfernt das aktuelle Ergebnis aus der App und setzt die Ansicht für eine neue Aufnahme zurück. Die bereits kopierte Fassung bleibt in der iOS-Zwischenablage.

## 11. Rückkehr zur vorherigen App

iOS bietet nicht dieselbe automatische Accessibility- und Paste-Funktion wie macOS.

Daher gilt für die erste Version:

- Blitztext kopiert das Ergebnis automatisch in die systemweite Zwischenablage.
- Blitztext fügt den Text nicht automatisch in die vorherige App ein.
- Blitztext schließt sich nicht programmgesteuert.
- Der Nutzer wechselt manuell zur vorherigen App und fügt den Text dort ein.
- Eine Share Extension oder eigene Tastatur kann später geprüft werden.

## 12. Speicherung und Datenschutz

- Es gibt keinen dauerhaften Verlauf.
- Frühere Transkriptionen werden nicht als Historie gespeichert.
- Temporäre Audiodateien werden nach erfolgreicher Verarbeitung und erfolgreichem Kopieren gelöscht.
- Bei Fehlern bleiben sie nur für `Erneut versuchen` erhalten.
- Bei `Aufnahme verwerfen` werden sie sofort gelöscht.
- Das aktuelle Ergebnis bleibt nur in der aktiven Sitzung sichtbar.
- Der API-Schlüssel wird nicht in UserDefaults, Logs oder Testdaten gespeichert.

## 13. Sichtbare Sprache

- Die Benutzeroberfläche ist zunächst vollständig deutschsprachig.
- Dazu gehören Buttons, Einstellungen, Aufnahmezustände, Fehlermeldungen und Datenschutztexte.
- Deutsch ist die Standardsprache für die Transkription.
- Weitere Transkriptionssprachen können später über die Einstellungen ergänzt werden.

## 14. Nicht Bestandteil der ersten Version

Folgende Funktionen werden bewusst zurückgestellt:

- lokale Transkription;
- iPad-Version;
- Querformat;
- dauerhafter Transkriptionsverlauf;
- eigene Workflow-Editoren;
- automatische Rückkehr in die vorherige App;
- automatisches Einfügen in beliebige andere Apps;
- Share Extension;
- eigene iOS-Tastatur;
- Widget oder Control-Center-Integration;
- TestFlight und App-Store-Veröffentlichung;
- Synchronisation zwischen Geräten;
- eigener Backend-Server als Vermittler zwischen App und OpenAI.

## 15. Technischer Startpunkt

Die Umsetzung beginnt nach diesen Entscheidungen mit:

1. iOS-App-Target in `apps/ios/` anlegen.
2. Bundle-ID `app.blitztext.ios` verwenden.
3. SwiftUI-App-Shell für iPhone und iOS 26 erstellen.
4. Deutsche Aufnahmeansicht mit Zustandsmodell anlegen.
5. App-Intent und App Shortcut für den zuletzt verwendeten Workflow vorbereiten.
6. Mikrofonberechtigung und Audioaufnahme implementieren.
7. Danach Keychain, Online-Transkription und Workflow-Ausführung anbinden.

Dieses Dokument beschreibt die Produktentscheidungen. Technische Detailentscheidungen wie Audioformat, konkrete API-Schicht, Teststruktur und genaue SwiftUI-Komponenten werden während der Umsetzung im Einklang mit diesen Vorgaben getroffen.
