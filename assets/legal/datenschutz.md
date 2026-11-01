# Datenschutzerklärung

*Stand: 01.11.2026*

Mit dieser Datenschutzerklärung informieren wir Sie darüber, welche personenbezogenen Daten wir bei der Nutzung unserer Anwendung erheben, zu welchen Zwecken wir sie verarbeiten und welche Rechte Ihnen nach der Datenschutz-Grundverordnung (DSGVO) zustehen.

## 1. Verantwortlicher
Verantwortlich für die Datenverarbeitung im Sinne der DSGVO ist:

[TODO: Name bzw. Firma]  
[TODO: Straße und Hausnummer]  
[TODO: PLZ und Ort], Deutschland  
E-Mail: [TODO: E-Mail-Adresse]  
Telefon: [TODO: Telefonnummer]

## 2. Hosting, Backend-Infrastruktur und Drittlandtransfer

### a) Datenbank und Authentifizierung (Supabase)
Für die Bereitstellung der Datenbank, die Nutzerauthentifizierung und die Speicherung der Anwendungsdaten nutzen wir den Dienst **Supabase** (Anbieter: Supabase, Inc., 970 Toa Payoh North #07-04, Singapore 318992 bzw. US-Muttergesellschaft).

* **Serverstandort (`eu-west-2`):** Sämtliche Anwendungs- und Kontodaten werden im Rechenzentrum in **London, Vereinigtes Königreich (AWS-Region `eu-west-2`)** gespeichert und verarbeitet.
* **Rechtsgrundlage für den Drittlandtransfer:** Für das Vereinigte Königreich besteht ein **Angemessenheitsbeschluss der Europäischen Kommission gemäß Art. 45 DSGVO**, wodurch ein der EU gleichwertiges Datenschutzniveau bestätigt ist. Darüber hinaus haben wir mit Supabase einen Auftragsverarbeitungsvertrag (Data Processing Addendum, Art. 28 DSGVO) inklusive der EU-Standardvertragsklauseln (SCC) abgeschlossen.
* **Rechtsgrundlage der Verarbeitung:** Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung zur Bereitstellung der App) sowie Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an einem sicheren und zuverlässigen Betrieb).

### b) Bereitstellung der Web-Anwendung (Web-Hosting)
Die Auslieferung der Web-Anwendung erfolgt über **Cloudflare Workers** (Anbieter: Cloudflare, Inc., USA; [TODO: Anschrift sowie Rechtsgrundlage für die Übermittlung in die USA ergänzen]). Beim Aufruf der Web-App werden durch den Hosting-Anbieter technisch notwendige Verbindungsdaten (insbesondere IP-Adresse, Zeitpunkt des Zugriffs, Browsertyp und Betriebssystem) in Server-Logfiles verarbeitet, um die Auslieferung und Sicherheit der Anwendung zu gewährleisten (Art. 6 Abs. 1 lit. f DSGVO).

## 3. Registrierung, Nutzerkonto und Profildaten

### a) Pflichtangaben für das Nutzerkonto und Gruppenprofil
Um die Anwendung nutzen zu können, ist die Erstellung eines Nutzerkontos erforderlich. Dabei verarbeiten wir folgende notwendige Daten:
* **E-Mail-Adresse und Passwort:** Ihre E-Mail-Adresse und Ihr Passwort werden für die Anmeldung über Supabase Auth verarbeitet. Das Passwort wird ausschließlich kryptografisch gehasht gespeichert; wir haben keinen Zugriff auf Ihr Passwort im Klartext.
* **Anzeigename (`display_name`):** Bei der Registrierung vergeben Sie einen Anzeigenamen (Pflichtfeld). Ihr Anzeigename ist für alle Mitglieder der Gruppen sichtbar, denen Sie angehören.
* **Spracheinstellung (`locale`):** Ihre gewählte App-Sprache (`de`, `en` oder `tr`) wird in Ihrem Profil gespeichert, um die Benutzeroberfläche entsprechend darzustellen.
* **Rechtsgrundlage:** Art. 6 Abs. 1 lit. b DSGVO (Erfüllung des Nutzungsvertrags).

### b) Freiwillige Stammdaten (`profile_private`)
Bei der Registrierung oder in Ihrem Profil haben Sie die Möglichkeit, folgende zusätzliche Angaben auf **freiwilliger Basis** zu hinterlegen:
* **Vorname und Nachname**
* **Telefonnummer** (inklusive Ländervorwahl; es erfolgt kein SMS-Versand zur Verifizierung)

Die Nutzung sämtlicher Funktionen der Anwendung ist auch ohne diese Angaben uneingeschränkt möglich. Sofern Sie diese Daten angeben, werden sie lediglich zur Vervollständigung Ihres persönlichen Kontoprofils für zukünftige Kontofunktionen gespeichert.

* **Strikte Zugriffsbeschränkung:** Diese Daten werden in einer technisch getrennten Tabelle (`profile_private`) gespeichert und durch datenbankseitige Zugriffsregeln (Row-Level Security) so geschützt, dass **ausschließlich Sie selbst** diese Angaben einsehen können. Andere Gruppenmitglieder haben keinen Zugriff darauf.
* **Rechtsgrundlage und Widerruf:** Die Verarbeitung dieser freiwilligen Angaben erfolgt ausschließlich auf Grundlage Ihrer **Einwilligung gemäß Art. 6 Abs. 1 lit. a DSGVO**. Sie können Ihre Einwilligung jederzeit mit Wirkung für die Zukunft widerrufen (Art. 7 Abs. 3 DSGVO), indem Sie die entsprechenden Angaben in Ihren Profileinstellungen entfernen, Ihr Konto löschen oder uns eine formlose Mitteilung per E-Mail senden. Durch den Widerruf wird die Rechtmäßigkeit der bis zum Widerruf erfolgten Verarbeitung nicht berührt.

## 4. Gruppenfunktionen, Einkaufslisten und Ausgabenverwaltung

Im Rahmen der Kernfunktionen der App verarbeiten wir die von Ihnen und Ihren Gruppenmitgliedern eingegebenen Daten:
* **Gruppen (`groups`):** Name der Gruppe sowie die Person, die sie angelegt hat.
* **Gruppenmitgliedschaften (`memberships`):** Zugehörigkeit zu einer Gruppe, Rolle (z. B. Admin/Mitglied) sowie Zeitpunkte des Beitritts und eines eventuellen Austritts (`left_at`).
* **Einladungscodes (`invites`):** Zum Einladen weiterer Mitglieder werden Einladungscodes generiert, die 7 Tage gültig sind und mit der erstellenden Person verknüpft werden.
* **Einkaufslisten, Ausgaben und Ausgleichszahlungen (`shopping_entries`, `expenses`, `expense_items`, `expense_shares`, `settlements`):** Erfasste Einkäufe, Beträge, Aufteilungen (Shares) und Zahlungen inklusive der Information, welches Mitglied den Eintrag wann erstellt bzw. bezahlt hat.

Diese Daten sind für alle Mitglieder der jeweiligen Gruppe einsehbar, um die gemeinsame Einkaufsplanung und Saldenberechnung durchzuführen. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO.

## 5. Lokale Speicherung auf Ihrem Endgerät (Kein Tracking)

Wir setzen **keine** Analyse-, Tracking- oder Werbe-Tools von Drittanbietern ein. Auf Ihrem Endgerät (`localStorage` im Browser bzw. `shared_preferences` in der App) werden lediglich zwei technisch notwendige bzw. rein lokale Informationen abgelegt:
1. **Authentifizierungs-Sitzung (Supabase Session):** Speichert Ihr Login-Token, damit Sie sich nicht bei jedem Seitenaufruf neu anmelden müssen. Dies ist technisch unbedingt erforderlich (§ 25 Abs. 2 TDDDG, Art. 6 Abs. 1 lit. b DSGVO).
2. **Design-Präferenz (System / Hell / Dunkel):** Ihre gewählte Theme-Einstellung wird ausschließlich lokal auf Ihrem jeweiligen Endgerät gespeichert und **nicht** an unsere Server übertragen.

## 6. Schriftarten und bedingter Abruf von Google Fonts (Fallback)

Unsere Anwendung nutzt die Schriftart „Inter" sowie die Web-Rendering-Engine (CanvasKit) und die Ersatzschriftart „Roboto". Diese Ressourcen sind lokal auf unserem Server eingebunden, sodass beim regulären Laden der Anwendung **keine Verbindung** zu Servern von Google hergestellt wird.

**Ausnahme bei Sonderzeichen und Emojis:** Sollte innerhalb der Anwendung ein Zeichen dargestellt werden (z. B. ein Emoji in einem Produktnamen auf der Einkaufsliste), das weder in „Inter" noch in „Roboto" lokal vorhanden ist, lädt das zugrundeliegende Framework (Flutter Web) die fehlende Ersatzschriftart dynamisch von `fonts.gstatic.com` nach. Anbieter ist die Google Ireland Limited, Gordon House, Barrow Street, Dublin 4, Irland (bzw. Google LLC, USA). Hierbei wird Ihre IP-Adresse an Google übertragen. Rechtsgrundlage ist unser berechtigtes Interesse an einer vollständigen und fehlerfreien Darstellung nutzergenerierter Inhalte gemäß Art. 6 Abs. 1 lit. f DSGVO. Für Datenübermittlungen in die USA ist Google LLC unter dem EU-U.S. Data Privacy Framework (DPF) zertifiziert.

## 7. Gruppen-Austritt, Kontolöschung und Anonymisierung

* **Austritt aus einer Gruppe:** Wenn Sie eine Gruppe verlassen, wird das Austrittsdatum (`left_at`) gespeichert. Bestehende Abrechnungsdaten bleiben erhalten, damit die Salden der Gruppe korrekt bleiben.
* **Vollständige Kontolöschung:** Sie können Ihr Konto jederzeit in den Einstellungen löschen („Konto löschen"). Bei der Löschung Ihres Kontos passiert Folgendes:
  1. Ihre Authentifizierungsdaten (`auth.users`) sowie Ihre freiwillig hinterlegten Stammdaten (Vorname, Nachname, Telefonnummer in `profile_private`) werden **unverzüglich und endgültig gelöscht**.
  2. Ihre aktiven Gruppenmitgliedschaften werden beendet. Sind Sie in einer aktiven Gruppe der einzige Administrator, wird die Administrator-Rolle automatisch an das am längsten aktive Gruppenmitglied übertragen. Sind Sie das letzte Mitglied einer Gruppe, wird diese Gruppe mit allen ihren Daten gelöscht.
  3. **Anonymisierung von Abrechnungsdaten:** Um die Integrität der Finanz- und Saldenberechnungen für die verbleibenden Gruppenmitglieder nicht zu zerstören, werden vergangene Ausgaben, Anteile und Ausgleichszahlungen nicht gelöscht, sondern **vollständig anonymisiert**. Ihr Anzeigename wird dabei dauerhaft durch den neutralen Platzhalter „Gelöschter Nutzer" ersetzt, sodass kein Personenbezug mehr zu Ihnen hergestellt werden kann (Art. 6 Abs. 1 lit. b und lit. f DSGVO).

## 8. Ihre Rechte als betroffene Person

[TODO: Abschnitt 8 vollständig einfügen (der Entwurf endet bei „Sie haben im Rahmen der").]
