# Datenschutz-Angaben für die Stores

Ausfüllhilfe für die Fragebögen in App Store Connect und der Google Play Console.
Grundlage: Lighthouse speichert alles lokal, hat keinen Server, keine Analyse und keine Werbung
(siehe `web/datenschutz.html` und `ios/Runner/PrivacyInfo.xcprivacy`).

## Apple – App Store Connect → App → „App-Datenschutz“

| Frage | Antwort |
|---|---|
| Datenschutzrichtlinien-URL | `https://<deine-domain>/datenschutz.html` |
| Erfassen du oder deine Drittanbieter Daten aus dieser App? | **Nein, wir erfassen keine Daten aus dieser App.** |

Ergebnis im Store: „Keine Daten erfasst“ / „Data Not Collected“.

Warum „Nein“ stimmt: Apple zählt nur Daten, die das Gerät verlassen und von dir oder Dritten
gespeichert werden. Einträge, Habits, Name und Einstellungen bleiben auf dem Gerät; Backups
speichert die Person selbst an einem Ort ihrer Wahl.

**Exportbestimmungen (Verschlüsselung):** schon beantwortet über
`ITSAppUsesNonExemptEncryption = false` in `ios/Runner/Info.plist`.

**TestFlight – externe Tester (Testinformationen):** Beta-App-Beschreibung, Feedback-E-Mail,
Datenschutz-URL (wie oben). Für interne Tester ist nichts davon nötig.

## Google – Play Console → App-Inhalte → „Datensicherheit“

| Frage | Antwort |
|---|---|
| Erhebt oder teilt deine App erforderliche Nutzerdatentypen? | **Nein** |
| Datenschutzerklärung (App-Inhalte → Datenschutzerklärung) | `https://<deine-domain>/datenschutz.html` |

Ergebnis im Store: „Keine Daten erfasst“ und „Keine Daten an Dritte weitergegeben“.

Weitere Punkte unter „App-Inhalte“:
- **Werbung:** Nein, die App enthält keine Werbung.
- **App-Zugriff:** Alle Funktionen ohne Anmeldung verfügbar.
- **Zielgruppe:** z. B. „18 und älter“ (keine Kinder-App – vermeidet die Familien-Richtlinien).
- **Berechtigungen:** Mitteilungen (abendliche Erinnerung, optional), Vibration und Start nach
  Geräteneustart (Erinnerung wiederherstellen).

## Vor dem Einreichen ausfüllen
- [ ] In `web/datenschutz.html` und `web/impressum.html` alle gelb markierten Platzhalter
      (`<mark class="todo">`) ersetzen: Name, Anschrift, E-Mail, Hosting-Anbieter, Log-Löschfrist.
- [ ] Web-App mit beiden Seiten veröffentlichen, sodass die URL öffentlich erreichbar ist.
- [ ] URL in App Store Connect und Play Console eintragen.

Hinweis: Die Texte sind eine sorgfältige Vorlage, ersetzen aber keine Rechtsberatung.
