# Datenschutzerklärung

*Stand: 10.11.2026*

Mit dieser Datenschutzerklärung informieren wir Sie darüber, welche personenbezogenen Daten wir bei der Nutzung unserer Anwendung („WG App“) erheben, zu welchen Zwecken wir sie verarbeiten und welche Rechte Ihnen nach der Datenschutz-Grundverordnung (DSGVO) zustehen.

---

## 1. Verantwortlicher
Verantwortlich für die Datenverarbeitung im Sinne der DSGVO ist:

[TODO: Name bzw. Vorname und Nachname]  
[TODO: Straße und Hausnummer]  
[TODO: PLZ und Ort], Deutschland  
E-Mail: [TODO: E-Mail-Adresse]  
Telefon: [TODO: Telefonnummer]

---

## 2. Hosting, Backend-Infrastruktur und Drittlandtransfer

### a) Datenbank und Authentifizierung (Supabase)
Für die Bereitstellung der relationalen Datenbank, die Nutzerauthentifizierung und die Speicherung der Anwendungsdaten nutzen wir den Dienst **Supabase** (Anbieter: Supabase, Inc., 970 Toa Payoh North #07-04, Singapur 318992 bzw. Supabase, Inc., 2261 Market Street #4779, San Francisco, CA 94114, USA).

- **Serverstandort (`eu-west-2`):** Sämtliche Anwendungs- und Kontodaten werden in der AWS-Region `eu-west-2` in **London, Vereinigtes Königreich** gespeichert und verarbeitet.
- **Logfiles bei API-Aufrufen:** Bei API-Anfragen an das Supabase-Backend verarbeitet der Anbieter aus technischen Gründen Verbindungsdaten (insbesondere IP-Adresse, HTTP-Header, Zeitstempel, aufgerufene Endpunkte) in Server-Logs, um die Betriebssicherheit, Stabilität und den Schutz vor Missbrauch sicherzustellen.
- **Auftragsverarbeitung und Drittlandtransfer:** Das Data Processing Addendum (DPA) von Supabase (abrufbar unter https://supabase.com/legal/dpa) ist gemäß den Nutzungsbedingungen von Supabase unmittelbar und ohne gesondertes Unterschriftsverfahren Vertragsbestandteil („incorporated into this Agreement“). Es regelt die Auftragsverarbeitung nach Art. 28 DSGVO und bindet die Standardvertragsklauseln der EU-Kommission (SCC gemäß Art. 46 Abs. 2 lit. c DSGVO) für etwaige Drittlandtransfers ein. Für den primären Verarbeitungsstandort im Vereinigten Königreich besteht zudem ein **Angemessenheitsbeschluss der Europäischen Kommission gemäß Art. 45 DSGVO**, wodurch ein der EU gleichwertiges Datenschutzniveau gewährleistet ist.
- **Rechtsgrundlage der Verarbeitung:** Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung zur Bereitstellung der App-Funktionen) sowie Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an einem stabilen, performanten und sicheren Datenbankbetrieb).

### b) Bereitstellung der Web-Anwendung (Web-Hosting über Cloudflare Workers)
Die Auslieferung der statischen Dateien und der Web-Anwendung erfolgt über das Edge-Netzwerk von **Cloudflare Workers** (Anbieter: Cloudflare, Inc., 101 Townsend St, San Francisco, CA 94107, USA).

- **Verarbeitung von Verbindungsdaten:** Beim Aufruf der Web-App über die bereitgestellte Webadresse verarbeitet Cloudflare technisch notwendige Verbindungsdaten (insbesondere IP-Adresse, HTTP-Header, Zugriffszeitstempel, Browsertyp, Betriebssystem) in temporären Server-Logfiles, um die weltweite Auslieferung, Performanz (Caching) und den Schutz vor Denial-of-Service-Angriffen (DDoS) sicherzustellen (Art. 6 Abs. 1 lit. f DSGVO).
- **Drittlandtransfer in die USA:** Cloudflare, Inc. ist unter dem **EU-U.S. Data Privacy Framework (DPF)** zertifiziert. Für Datenübermittlungen an nach dem DPF zertifizierte US-Unternehmen besteht ein Angemessenheitsbeschluss der Europäischen Kommission gemäß Art. 45 DSGVO. Ergänzend greifen die Standardvertragsklauseln (SCC) im Rahmen des Cloudflare Data Processing Addendum.
- **Hinweis zu Cookies auf `*.workers.dev`:** Die Web-Anwendung setzt selbst keinerlei Cookies. [PRÜFEN: Ob Cloudflare auf Subdomains unter workers.dev eigene technisch notwendige Sicherheits-Cookies setzt, ist vor Live-Schaltung unter der produktiven Domain zu verifizieren.]

---

## 3. Registrierung, Nutzerkonto und Profildaten

### a) Pflichtangaben für das Nutzerkonto und Gruppenprofil
Um die Anwendung nutzen zu können, ist die Erstellung eines Nutzerkontos erforderlich. Dabei verarbeiten wir folgende notwendige Daten:
- **E-Mail-Adresse und Passwort:** Ihre E-Mail-Adresse und Ihr Passwort werden für die Registrierung und Anmeldung über Supabase Auth verarbeitet. Das Passwort wird ausschließlich kryptografisch gehasht gespeichert; wir haben zu keinem Zeitpunkt Zugriff auf Ihr Passwort im Klartext.
- **Anzeigename (`display_name`):** Bei der Registrierung vergeben Sie einen Anzeigenamen (Pflichtfeld). Ihr Anzeigename ist für alle Mitglieder der Gruppen sichtbar, denen Sie beitreten oder angehören.
- **Spracheinstellung (`locale`):** Ihre gewählte App-Sprache (`de`, `en` oder `tr`) wird in Ihrem Profil gespeichert, um die Benutzeroberfläche entsprechend darzustellen.
- **Rechtsgrundlage:** Art. 6 Abs. 1 lit. b DSGVO (Erfüllung des Nutzungsverhältnisses).

### b) Freiwillige Stammdaten (`profile_private`)
Bei der Registrierung oder in Ihrem Profil haben Sie die Möglichkeit, folgende zusätzliche Angaben auf **freiwilliger Basis** zu hinterlegen:
- **Vorname und Nachname**
- **Telefonnummer** (inklusive Ländervorwahl; es erfolgt kein SMS-Versand zur Verifizierung)

Die Nutzung sämtlicher Kernfunktionen der Anwendung ist auch ohne diese Angaben uneingeschränkt möglich.

- **Strikte Zugriffsbeschränkung:** Diese Daten werden in einer getrennten Datenbanktabelle (`profile_private`) gespeichert und durch datenbankseitige Zugriffsregeln (Row-Level Security, RLS) so isoliert, dass **ausschließlich Sie selbst** über Ihr Nutzerkonto diese Angaben abrufen und einsehen können. Andere Gruppenmitglieder oder Dritte haben keinen Zugriff darauf.
- **Rechtsgrundlage und Widerruf:** Die Verarbeitung erfolgt auf Grundlage Ihrer **Einwilligung gemäß Art. 6 Abs. 1 lit. a DSGVO**. Sie können Ihre Einwilligung jederzeit mit Wirkung für die Zukunft widerrufen (Art. 7 Abs. 3 DSGVO), indem Sie die entsprechenden Felder in den Einstellungen leeren und speichern oder Ihr gesamtes Konto löschen.

### c) E-Mail-Versand und Passwort-Reset
Derzeit versendet die Anwendung keine regelmäßigen E-Mails oder Verifizierungsnachrichten. Sofern Sie künftig die Funktion „Passwort vergessen“ in Anspruch nehmen, wird über die Authentifizierungsinfrastruktur von Supabase eine automatisierte Transaktions-E-Mail mit einem Einmal-Link zur Passwortrücksetzung an Ihre hinterlegte E-Mail-Adresse übermittelt. Rechtsgrundlage hierfür ist Art. 6 Abs. 1 lit. b DSGVO (Bereitstellung des Zugangs zum Nutzerkonto).

---

## 4. Gruppenfunktionen, Einkaufslisten und Ausgabenverwaltung

Im Rahmen der Kernfunktionen der Anwendung verarbeiten wir die von Ihnen und Ihren Gruppenmitgliedern eingegebenen Daten:
- **Gruppen (`groups`):** Name der Gruppe sowie Kennung der erstellenden Person.
- **Gruppenmitgliedschaften (`memberships`):** Zugehörigkeit zu einer Gruppe, zugewiesene Rolle (Administrator oder reguläres Mitglied), Zeitpunkte des Beitritts sowie gegebenenfalls des Austritts (`left_at`).
- **Einladungscodes (`invites`):** Zur Aufnahme neuer Mitglieder generierte Einladungscodes (Gültigkeit: 7 Tage), die mit der Kennung der erstellenden Person verknüpft sind. Abgelaufene Codes verbleiben derzeit zu Referenzzwecken in der Datenbank.
- **Einkaufslisten, Ausgaben und Ausgleichszahlungen (`shopping_entries`, `expenses`, `expense_items`, `expense_shares`, `settlements`):** Erfasste Einkäufe, Beträge, Datumsangaben, Beschreibungstexte, Kostenanteile und Ausgleichszahlungen, jeweils verknüpft mit der Kennung des eintragenden bzw. zahlenden Gruppenmitglieds.

Diese Daten sind für alle aktuellen Mitglieder der jeweiligen Gruppe transparent einsehbar, um den gemeinsamen Zweck (Einkaufsabstimmung und Saldoberechnung) zu erfüllen. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO.

---

## 5. Lokale Speicherung auf Ihrem Endgerät (Kein Tracking)

Wir setzen **keine** Analyse-, Tracking- oder Werbedienste von Drittanbietern ein. Auf Ihrem Endgerät (im `localStorage` Ihres Browsers) werden ausschließlich folgende technisch notwendige bzw. rein lokale Daten abgelegt:
1. **Authentifizierungs-Sitzung (Supabase Auth Token):** Speichert Ihr Sitzungstoken lokal, um Ihre Anmeldung über mehrere Seitenaufrufe hinweg aufrechtzuerhalten. Dies ist technisch zwingend erforderlich (§ 25 Abs. 2 Nr. 2 TDDDG, Art. 6 Abs. 1 lit. b DSGVO).
2. **Design-Präferenz (Theme):** Ihre Auswahl für das Farbschema (Systemstandard, Hell oder Dunkel) wird ausschließlich lokal im Browser gespeichert und **nicht** an unsere Server oder Dritte übertragen.

---

## 6. Schriftarten und bedingter Abruf von Google Fonts (Fallback)

Unsere Anwendung bindet die Hauptschriftarten („Inter“, „Roboto“) sowie die Web-Rendering-Engine („CanvasKit“) lokal von unserem Hosting-Server ein. Beim regulären Laden der Anwendung findet **keine** Verbindung zu externen Servern von Google statt.

**Bedingter Abruf bei Sonderzeichen und Emojis:**  
Sollte auf der Benutzeroberfläche ein nutzergeneriertes Zeichen (z. B. ein Emoji oder spezielles Sonderzeichen in einem Einkaufs- oder Ausgabeneintrag) angezeigt werden müssen, das in den lokalen Schriftdateien nicht enthalten ist, lädt das Framework (Flutter Web) die erforderliche Ersatzschriftart dynamisch von Servern der **Google Ireland Limited** (Gordon House, Barrow Street, Dublin 4, Irland; Muttergesellschaft: Google LLC, 1600 Amphitheatre Parkway, Mountain View, CA 94043, USA) über die Domain `fonts.gstatic.com` nach. Hierbei wird technisch bedingt Ihre IP-Adresse an Google übertragen.

- **Rechtsgrundlage:** Berechtigtes Interesse gemäß Art. 6 Abs. 1 lit. f DSGVO an einer fehlerfreien und lesbaren typografischen Darstellung aller App-Inhalte.
- **Drittlandtransfer:** Für eventuelle Datenübertragungen an die US-Muttergesellschaft Google LLC gilt der Angemessenheitsbeschluss der Europäischen Kommission, da Google LLC unter dem EU-U.S. Data Privacy Framework zertifiziert ist.

---

## 7. Speicherdauer, Gruppenaustritt, Kontolöschung und Anonymisierung

### a) Allgemeine Speicherdauer
Personenbezogene Daten werden nur so lange verarbeitet, wie dies für die Bereitstellung der App-Funktionen erforderlich ist oder gesetzliche Aufbewahrungsfristen bestehen.

### b) Gruppenaustritt
Beim Austritt aus einer Gruppe wird der Zeitpunkt des Austritts (`left_at`) in der Mitgliedschaftstabelle vermerkt. Bisherige Ausgaben- und Einkaufsdaten bleiben innerhalb der Gruppe bestehen, damit der historische Saldenstand für alle verbleibenden Mitglieder nachvollziehbar bleibt.

### c) Vollständige Kontolöschung und Anonymisierung
Sie können Ihr Konto jederzeit selbstständig in den Kontoeinstellungen („Konto löschen“) auflösen. Hierbei greift folgender technischer Prozess:
1. **Löschung von Identifikations- und Stammdaten:** Ihre Authentifizierungsdaten (E-Mail-Adresse, Passwort-Hash in `auth.users`) sowie sämtliche freiwillig hinterlegten Kontaktdaten in `profile_private` (Vorname, Nachname, Telefonnummer) werden **sofort und unwiderruflich gelöscht**.
2. **Bereinigung von Mitgliedschaften:** Sie werden aus allen aktiven Gruppen ausgetragen. Sind Sie in einer Gruppe der einzige Administrator, geht diese Rolle automatisch auf das am längsten der Gruppe angehörende aktive Mitglied über. Sind Sie das letzte verbliebene Mitglied einer Gruppe, wird die gesamte Gruppe einschließlich aller Listen und Ausgabendaten gelöscht.
3. **Anonymisierung der Finanzhistorie:** Zur Wahrung der rechnerischen Integrität der Salden für die verbleibenden Gruppenmitglieder werden vergangene Ausgaben, Anteile und Ausgleichszahlungen nicht gelöscht, sondern **vollständig anonymisiert**. Ihr bisheriger Anzeigename (`display_name`) wird datenbankseitig dauerhaft durch den neutralen Textwert **„Gelöschter Nutzer“** ersetzt. Da die zugehörigen Authentifizierungs- und privaten Profildaten gelöscht sind, ist ein Rückschluss auf Ihre Person ausgeschlossen.

---

## 8. Empfänger von personenbezogenen Daten
Im Rahmen des Betriebs der Anwendung werden personenbezogene Daten an folgende Auftragsverarbeiter gemäß Art. 28 DSGVO übermittelt:
- **Cloudflare, Inc.:** Auslieferung der Web-Anwendung, DDoS-Schutz und temporäre Protokollierung von Verbindungsdaten.
- **Supabase, Inc. (und genutzte Hosting-Infrastruktur von AWS im UK):** Datenbank-Hosting, Nutzerverwaltung, Authentifizierung und Datenspeicherung.
- **Google Ireland Limited / Google LLC:** Nur im Ausnahmefall beim dynamischen Nachladen von Ersatzschriftarten (IP-Adresse).

Eine Weitergabe an unbefugte Dritte oder ein Verkauf Ihrer Daten findet nicht statt.

---

## 9. Ihre Rechte als betroffene Person

Ihnen stehen nach der DSGVO bei Vorliegen der jeweiligen gesetzlichen Voraussetzungen folgende Rechte zu:

- **Auskunftsrecht (Art. 15 DSGVO):** Sie haben das Recht, eine Bestätigung darüber zu verlangen, ob wir Sie betreffende personenbezogene Daten verarbeiten, und Auskunft über diese Daten sowie weitergehende Informationen zu erhalten.
- **Recht auf Berichtigung (Art. 16 DSGVO):** Sie können die unverzügliche Berichtigung unrichtiger oder die Vervollständigung Ihrer bei uns gespeicherten Daten verlangen (viele Angaben können Sie direkt in Ihren Kontoeinstellungen anpassen).
- **Recht auf Löschung („Recht auf Vergessenwerden“, Art. 17 DSGVO):** Sie haben das Recht, die Löschung Ihrer Daten zu verlangen, insbesondere wenn diese für die vorgesehenen Zwecke nicht mehr erforderlich sind oder Sie Ihre Einwilligung widerrufen haben (siehe auch Abschnitt 7 zur Funktion „Konto löschen“).
- **Recht auf Einschränkung der Verarbeitung (Art. 18 DSGVO):** Sie können verlangen, dass die Verarbeitung Ihrer Daten eingeschränkt wird, etwa solange die Richtigkeit von Ihnen bestritten wird.
- **Recht auf Datenübertragbarkeit (Art. 20 DSGVO):** Sie haben das Recht, Daten, die Sie uns bereitgestellt haben und die wir automatisiert auf Grundlage Ihrer Einwilligung oder eines Vertrags verarbeiten, in einem strukturierten, gängigen und maschinenlesbaren Format zu erhalten.
- **Widerspruchsrecht (Art. 21 DSGVO):** Verarbeiten wir Daten auf Grundlage unseres berechtigten Interesses gemäß Art. 6 Abs. 1 lit. f DSGVO, haben Sie das Recht, aus Gründen, die sich aus Ihrer besonderen Situation ergeben, jederzeit Widerspruch gegen diese Verarbeitung einzulegen.
- **Widerruf erteilter Einwilligungen (Art. 7 Abs. 3 DSGVO):** Sie können jede erteilte Einwilligung (z. B. für freiwillige Angaben in `profile_private`) jederzeit mit Wirkung für die Zukunft widerrufen.
- **Beschwerderecht bei einer Aufsichtsbehörde (Art. 77 DSGVO):** Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde über die Verarbeitung Ihrer Daten zu beschweren. Sie können sich hierfür an die für Ihren gewöhnlichen Aufenthaltsort, Ihren Arbeitsplatz oder unseren Wohnsitz zuständige Aufsichtsbehörde wenden.

---

## 10. Bereitstellungspflicht und Automatisierte Entscheidungsfindung
Die Bereitstellung Ihrer E-Mail-Adresse, eines Passworts und eines frei wählbaren Anzeigenamens ist für den Abschluss und die Durchführung des Nutzungsverhältnisses erforderlich. Ohne diese Angaben kann kein Nutzerkonto eingerichtet werden. Die Angabe von Vor- und Nachname sowie Telefonnummer ist rein freiwillig.

Eine automatisierte Entscheidungsfindung einschließlich Profiling gemäß Art. 22 DSGVO findet in unserer Anwendung nicht statt.

---

## 11. Aktualität und Änderung dieser Datenschutzerklärung
Durch die Weiterentwicklung unserer Anwendung (z. B. Implementierung einer eigenen Domain oder Aktivierung des Passwort-Reset-Mailsystems) oder geänderte rechtliche Vorgaben kann eine Anpassung dieser Datenschutzerklärung erforderlich werden. Die jeweils aktuelle Fassung kann jederzeit innerhalb der Anwendung eingesehen werden.
