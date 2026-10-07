# Werkbuch Aufgaben

Aufgaben-App für Baustellen, Produktion, Intern, Lehrlinge und Sicherheit.
Läuft im Browser und als App auf Handy, Tablet und PC (Startbildschirm), auch offline.

## Aufbau

- `index.html` – die ganze App
- `config.js` – Verbindung zu Supabase (Project URL und öffentlicher anon-Schlüssel)
- `sw.js`, `manifest.webmanifest`, `icon-*.png` – Installation als App und Offline-Betrieb
- `supabase/schema.sql` – Tabellen, Zugriffsregeln und Dateispeicher; einmal im SQL Editor ausführen
- `supabase/functions/meeting` – optionale Meeting-Zusammenfassung mit Claude (braucht einen eigenen API-Schlüssel)

## Daten

Alles wird zuerst auf dem Gerät gespeichert und dann mit Supabase abgeglichen.
Jeder Benutzer sieht nur seine eigenen Aufgaben, Bereiche, Meetings und Anhänge.
