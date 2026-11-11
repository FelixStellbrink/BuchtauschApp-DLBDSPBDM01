-- =====================================================================
-- Buchtausch-App - Datenbank
-- Portfolio DLBDSPBDM01_D, Phase 3
--
-- Installationsanleitung:
--   1. Datenbank anlegen: CREATE DATABASE buchtausch;
--   2. Mit der Datenbank verbinden.
--   3. Dieses Skript vollstaendig ausfuehren.
--
-- Das Skript ist wiederholbar: Der DROP-Block loescht vorhandene
-- Tabellen in umgekehrter Reihenfolge, bevor neu angelegt wird.
--
-- Aufbau:
--   Teil 1  Aufraeumen
--   Teil 2  Tabellen
--   Teil 3  Trigger
--   Teil 4  Daten
--   Teil 5  Sequenzen
-- =====================================================================


-- =====================================================================
-- TEIL 1: AUFRAEUMEN
-- Umgekehrte Reihenfolge wegen der Fremdschluessel.
-- =====================================================================
DROP TABLE IF EXISTS bewertung;
DROP TABLE IF EXISTS ausleihe;
DROP TABLE IF EXISTS anfrage;
DROP TABLE IF EXISTS exemplar;
DROP TABLE IF EXISTS uebergabeart;
DROP TABLE IF EXISTS buch_autor;
DROP TABLE IF EXISTS buch_genre;
DROP TABLE IF EXISTS buch;
DROP TABLE IF EXISTS autor;
DROP TABLE IF EXISTS genre;
DROP TABLE IF EXISTS sprache;
DROP TABLE IF EXISTS nutzer;
DROP TABLE IF EXISTS ort;


-- =====================================================================
-- TEIL 2: TABELLEN
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabelle ort: Referenzdaten Wohnort.
-- PLZ als natuerlicher Primaerschluessel.
-- Dadurch werden Doppeleintraege automatisch verhindert.
-- CHAR statt INT, damit 0 am Anfang erhalten bleibt.
-- ---------------------------------------------------------------------
CREATE TABLE ort (
    postleitzahl CHAR(5) PRIMARY KEY,
    stadt        VARCHAR(100) NOT NULL,
    bundesland   VARCHAR(50)  NOT NULL
);


-- ---------------------------------------------------------------------
-- Tabelle nutzer: Personendaten.
-- nutzer_id als kuenstlicher Primaerschluessel.
-- Passwort wird gehasht gespeichert.
-- strasse und hausnummer duerfen leer bleiben, sie werden erst beim
-- Versand benoetigt. Die postleitzahl ist Pflicht, da die Filterung
-- darauf aufbaut.
-- ---------------------------------------------------------------------
CREATE TABLE nutzer (
    nutzer_id     SERIAL PRIMARY KEY,
    vorname       VARCHAR(50)  NOT NULL,
    nachname      VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) UNIQUE CHECK (email LIKE '%@%') NOT NULL,
    passwort_hash VARCHAR(255) NOT NULL,
    strasse       VARCHAR(100),
    hausnummer    VARCHAR(10),
    postleitzahl  CHAR(5) NOT NULL,
    FOREIGN KEY (postleitzahl) REFERENCES ort(postleitzahl)
);


-- ---------------------------------------------------------------------
-- Tabelle sprache: Referenzdaten.
-- sprach_id als kuenstlicher Primaerschluessel.
-- UNIQUE verhindert doppelte Belegung von Sprachen.
-- ---------------------------------------------------------------------
CREATE TABLE sprache (
    sprach_id SERIAL PRIMARY KEY,
    sprache   VARCHAR(20) UNIQUE NOT NULL
);


-- ---------------------------------------------------------------------
-- Tabelle genre: Referenzdaten.
-- genre_id als kuenstlicher Primaerschluessel.
-- UNIQUE verhindert doppelte Belegung von Genres.
-- ---------------------------------------------------------------------
CREATE TABLE genre (
    genre_id SERIAL PRIMARY KEY,
    genre    VARCHAR(50) UNIQUE NOT NULL
);


-- ---------------------------------------------------------------------
-- Tabelle autor: bibliografische Daten.
-- autor_id als kuenstlicher Primaerschluessel.
-- Hier kein UNIQUE, da es mehrere Autoren mit demselben Namen geben kann.
-- ---------------------------------------------------------------------
CREATE TABLE autor (
    autor_id SERIAL PRIMARY KEY,
    vorname  VARCHAR(50) NOT NULL,
    nachname VARCHAR(50) NOT NULL
);


-- ---------------------------------------------------------------------
-- Tabelle buch: bibliografische Daten.
-- isbn als natuerlicher Primaerschluessel.
-- SMALLINT, da Wertebereich bis 32767 als Jahreszahl ausreicht.
-- erscheinungsjahr begrenzt, Buchdruck begann 1440.
-- 2100 damit die Datenbank nicht jedes Jahr aktualisiert werden muss.
-- ---------------------------------------------------------------------
CREATE TABLE buch (
    isbn             CHAR(13) PRIMARY KEY,
    titel            VARCHAR(200) NOT NULL,
    erscheinungsjahr SMALLINT CHECK (erscheinungsjahr BETWEEN 1440 AND 2100) NOT NULL,
    sprach_id        INT NOT NULL,
    FOREIGN KEY (sprach_id) REFERENCES sprache(sprach_id)
);


-- ---------------------------------------------------------------------
-- Tabelle buch_genre: Ueberfuehrungstabelle.
-- isbn und genre_id als zusammengesetzter Primaerschluessel.
-- Beide sind Fremdschluessel aus anderen Tabellen.
-- ON DELETE CASCADE: wird ein Buch geloescht, verschwinden die
-- Genre-Zuordnungen. Das Genre bleibt bestehen und laesst sich nicht
-- loeschen, solange Buecher daran haengen.
-- ---------------------------------------------------------------------
CREATE TABLE buch_genre (
    isbn     CHAR(13) NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (isbn, genre_id),
    FOREIGN KEY (isbn)     REFERENCES buch(isbn) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);


-- ---------------------------------------------------------------------
-- Tabelle buch_autor: Ueberfuehrungstabelle.
-- isbn und autor_id als zusammengesetzter Primaerschluessel.
-- Beide sind Fremdschluessel aus anderen Tabellen.
-- ON DELETE CASCADE: wird ein Buch geloescht, verschwinden die
-- Autor-Zuordnungen. Der Autor bleibt bestehen und laesst sich nicht
-- loeschen, solange Buecher daran haengen.
-- ---------------------------------------------------------------------
CREATE TABLE buch_autor (
    isbn     CHAR(13) NOT NULL,
    autor_id INT NOT NULL,
    PRIMARY KEY (isbn, autor_id),
    FOREIGN KEY (isbn)     REFERENCES buch(isbn) ON DELETE CASCADE,
    FOREIGN KEY (autor_id) REFERENCES autor(autor_id)
);


-- ---------------------------------------------------------------------
-- Tabelle uebergabeart: Referenzdaten.
-- art_id als kuenstlicher Primaerschluessel.
-- CHECK, da uebergabe nur Abholung oder Versand sein soll.
-- UNIQUE, damit Abholung und Versand nicht mehrfach angelegt werden.
-- Diese Tabelle hat als einzige nur zwei Eintraege. Die Wertemenge ist
-- fachlich abgeschlossen, weitere Zeilen waeren nicht sinnvoll.
-- ---------------------------------------------------------------------
CREATE TABLE uebergabeart (
    art_id    SERIAL PRIMARY KEY,
    uebergabe VARCHAR(20) NOT NULL UNIQUE
                CHECK (uebergabe IN ('Abholung', 'Versand'))
);


-- ---------------------------------------------------------------------
-- Tabelle exemplar: Bestandsdaten.
-- exemplar_id als kuenstlicher Primaerschluessel.
-- CHECK, damit status und zustand nur bestimmte Werte haben duerfen.
-- Kein ON DELETE CASCADE: soll ein Nutzer oder Buch geloescht werden,
-- wird das verhindert, solange noch Exemplare daran haengen.
-- ---------------------------------------------------------------------
CREATE TABLE exemplar (
    exemplar_id SERIAL PRIMARY KEY,
    status      VARCHAR(20) CHECK (status IN ('Verfuegbar', 'Verliehen', 'Archiviert')) NOT NULL,
    zustand     VARCHAR(20) CHECK (zustand IN ('Hervorragend', 'Gut', 'Schlecht')) NOT NULL,
    nutzer_id   INT NOT NULL,
    isbn        CHAR(13) NOT NULL,
    FOREIGN KEY (nutzer_id) REFERENCES nutzer(nutzer_id),
    FOREIGN KEY (isbn)      REFERENCES buch(isbn)
);


-- ---------------------------------------------------------------------
-- Tabelle anfrage: Vorgangsdaten.
-- anfrage_id als kuenstlicher Primaerschluessel.
-- Fremdschluessel aus nutzer, exemplar und uebergabeart.
-- CHECK, damit status nur bestimmte Werte haben kann.
-- ---------------------------------------------------------------------
CREATE TABLE anfrage (
    anfrage_id  SERIAL PRIMARY KEY,
    status      VARCHAR(20) CHECK (status IN ('Gestellt', 'Angenommen', 'Abgelehnt')) NOT NULL,
    nutzer_id   INT NOT NULL,
    exemplar_id INT NOT NULL,
    art_id      INT NOT NULL,
    FOREIGN KEY (nutzer_id)   REFERENCES nutzer(nutzer_id),
    FOREIGN KEY (exemplar_id) REFERENCES exemplar(exemplar_id),
    FOREIGN KEY (art_id)      REFERENCES uebergabeart(art_id)
);

-- ---------------------------------------------------------------------
-- UNIQUE INDEX anfrage_angenommen.
-- Stellt sicher, dass es je Exemplar hoechstens eine angenommene Anfrage gibt.
-- Mehrere Nutzer duerfen dasselbe Exemplar anfragen, abgelehnte Anfragen bleiben erhalten.
-- Nur der Zustand angenommen darf einmalig sein.
-- Ohne die WHERE-Bedingung duerfte jedes Exemplar nur einmal angefragt werden.
-- Ein CHECK reicht nicht, weil er nur die eingefuegte Zeile sieht. 
-- Der Index prueft dagegen alle Zeilen der Tabelle.
-- ---------------------------------------------------------------------

CREATE UNIQUE INDEX anfrage_angenommen
ON anfrage (exemplar_id)
WHERE status='Angenommen';


-- ---------------------------------------------------------------------
-- Tabelle ausleihe: Vorgangsdaten.
-- ausleih_id als kuenstlicher Primaerschluessel.
-- Fremdschluessel aus nutzer, exemplar und uebergabeart.
-- ausleihdauer ist die vereinbarte Dauer in Tagen, enddatum die
-- tatsaechliche Rueckgabe. Weichen beide voneinander ab, liegt eine
-- verspaetete Rueckgabe vor. Die Spalte ist daher nicht redundant.
-- CHECK: ausleihdauer muss groesser als 0 sein.
-- CHECK: enddatum darf nicht vor startdatum liegen. Ein Buch darf am
-- selben Tag zurueckgegeben werden, daher <=.
-- enddatum bleibt leer, solange die Ausleihe laeuft.
-- ---------------------------------------------------------------------
CREATE TABLE ausleihe (
    ausleih_id   SERIAL PRIMARY KEY,
    startdatum   DATE NOT NULL,
    enddatum     DATE,
    ausleihdauer INT NOT NULL CHECK (ausleihdauer > 0),
    nutzer_id    INT NOT NULL,
    exemplar_id  INT NOT NULL,
    art_id       INT NOT NULL,
    FOREIGN KEY (nutzer_id)   REFERENCES nutzer(nutzer_id),
    FOREIGN KEY (exemplar_id) REFERENCES exemplar(exemplar_id),
    FOREIGN KEY (art_id)      REFERENCES uebergabeart(art_id),
    CHECK (startdatum <= enddatum)
);


-- ---------------------------------------------------------------------
-- UNIQUE INDEX ausleihe_aktiv.
-- Stellt sicher, dass es je Exemplar hoechstens eine aktive Ausleihe gibt.
-- Index ist partiell, weil ein Exemplar mehrfach in ausleihe stehen darf 
-- Ohne die WHERE-Bedingung waere jede exemplar_id nur einmal erlaubt
-- und die Historie unmoeglich.
-- Zusaetzlich zum Trigger noetig: trg_verfuegbarkeit verlaesst sich auf
-- exemplar.status. Wenn dieser falsch ist, laesst er eine zweite Ausleihe zu. 
-- Der Index prueft die Ausleihe selbst.
-- ---------------------------------------------------------------------

CREATE UNIQUE INDEX ausleihe_aktiv
ON ausleihe (exemplar_id)
WHERE enddatum IS NULL;


-- ---------------------------------------------------------------------
-- Tabelle bewertung: Vorgangsdaten.
-- bewertung_id als kuenstlicher Primaerschluessel.
-- Fremdschluessel aus ausleihe.
-- UNIQUE, damit pro Ausleihe nur eine Bewertung moeglich ist.
-- CHECK, damit sterne zwischen 1 und 5 liegen.
-- kommentar ist optional.
-- ---------------------------------------------------------------------
CREATE TABLE bewertung (
    bewertung_id SERIAL PRIMARY KEY,
    sterne       SMALLINT CHECK (sterne BETWEEN 1 AND 5) NOT NULL,
    kommentar    VARCHAR(500),
    ausleih_id   INT UNIQUE NOT NULL,
    FOREIGN KEY (ausleih_id) REFERENCES ausleihe(ausleih_id)
);


-- =====================================================================
-- TEIL 3: TRIGGER
-- =====================================================================

-- ---------------------------------------------------------------------
-- Trigger Verfuegbarkeit.
-- Prueft, ob das Exemplar einen anderen Status als Verfuegbar hat.
-- Startet jedes Mal, wenn eine Ausleihe angelegt werden soll.
-- Trigger noetig, da die Information in exemplar liegt, nicht in
-- ausleihe. Ein CHECK kann nur Spalten derselben Zeile pruefen.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pruefe_verfuegbarkeit()
RETURNS TRIGGER AS $$
BEGIN
IF
(SELECT status FROM exemplar WHERE exemplar_id = NEW.exemplar_id) <> 'Verfuegbar'
THEN RAISE EXCEPTION 'Exemplar % ist nicht verfuegbar.', NEW.exemplar_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verfuegbarkeit
BEFORE INSERT ON ausleihe
FOR EACH ROW
EXECUTE FUNCTION pruefe_verfuegbarkeit();


-- ---------------------------------------------------------------------
-- Trigger Bewertung.
-- Prueft, ob das Enddatum der Ausleihe einen Wert hat.
-- Startet jedes Mal, wenn eine Bewertung angelegt werden soll.
-- Trigger noetig, da die Information in ausleihe liegt, nicht in
-- bewertung.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pruefe_bewertung()
RETURNS TRIGGER AS $$
BEGIN
IF
(SELECT enddatum FROM ausleihe WHERE ausleih_id = NEW.ausleih_id) IS NULL
THEN RAISE EXCEPTION 'Ausleihe % ist noch nicht beendet, Bewertung nicht moeglich', NEW.ausleih_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bewertung
BEFORE INSERT OR UPDATE ON bewertung
FOR EACH ROW
EXECUTE FUNCTION pruefe_bewertung();


-- ---------------------------------------------------------------------
-- Trigger Status
-- Prueft, ob enddatum NULL ist
-- Wenn enddatum NULL: 
-- Setzt den status von Verfuegbar auf Verliehen bei exemplar.
-- Wenn enddatum nicht NULL:
-- Prueft, ob der status Verliehen ist, damit keine archivierten Exemplare betroffen sind. 
-- Setzt status auf 'Verfuegbar'
-- Startet jedes Mal, nachdem eine Zeile angelegt oder bearbeitet wurde 
-- Trigger noetig, da die Information in exemplar liegt, der Ausloeser in ausleihe
-- AFTER statt BEFORE: Da bei zwei BEFORE-Triggern derselben Tabelle diese alphabetisch
-- ausgefuehrt werden. Es wuerde ein Status gesetzt, bevor geprueft wird, ob exemplar verfuegbar ist
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION setze_status()
RETURNS TRIGGER AS $$
BEGIN
IF NEW.enddatum IS NULL
THEN UPDATE exemplar SET status='Verliehen'
			WHERE exemplar_id=NEW.exemplar_id;

ELSE
 UPDATE exemplar SET status='Verfuegbar'
	WHERE exemplar_id=NEW.exemplar_id 
	AND status='Verliehen';
END IF; RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_status
AFTER INSERT OR UPDATE ON ausleihe
FOR EACH ROW
EXECUTE FUNCTION setze_status();


-- ---------------------------------------------------------------------
-- Trigger Anfrage
-- Prueft, ob die Anfrage vom Besitzer kommt
-- Prueft, ob nutzer_id aus der neuen Anfrage dieselbe wie des Exemplars ist
-- Startet jedes Mal, bevor eine Zeile angelegt oder veraendert wird 
-- Trigger noetig, da die Information in exemplar liegt, der Ausloeser in anfrage
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pruefe_anfrage()
RETURNS TRIGGER AS $$
BEGIN
IF
(SELECT nutzer_id FROM exemplar WHERE exemplar_id = NEW.exemplar_id)
= NEW.nutzer_id
THEN RAISE EXCEPTION 'Nutzer % besitzt dieses Exemplar.', NEW.nutzer_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_anfrage
BEFORE INSERT OR UPDATE ON anfrage
FOR EACH ROW
EXECUTE FUNCTION pruefe_anfrage();


-- =====================================================================
-- TEIL 4: DATEN
--
-- Die Reihenfolge der INSERT-Bloecke folgt den Fremdschluessel-
-- abhaengigkeiten: zuerst die Tabellen, auf die verwiesen wird.
-- Die Schluesselwerte werden ausdruecklich mitgegeben, weil die
-- Datensaetze untereinander darauf verweisen.
-- =====================================================================

-- ---------------------------------------------------------------------
-- ort (10 Eintraege)
-- Zwei Postleitzahlen je Stadt bei Hamburg, Berlin, Muenchen und Weimar.
-- Das belegt, warum die PLZ und nicht die Stadt der Schluessel ist.
-- ---------------------------------------------------------------------
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('22767', 'Hamburg', 'Hamburg');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('10115', 'Berlin', 'Berlin');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('80636', 'Muenchen', 'Bayern');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('58099', 'Hagen', 'NRW');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('99423', 'Weimar', 'Thueringen');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('01067', 'Dresden', 'Sachsen');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('20457', 'Hamburg', 'Hamburg');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('10961', 'Berlin', 'Berlin');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('81377', 'Muenchen', 'Bayern');
INSERT INTO ort (postleitzahl, stadt, bundesland) VALUES ('99425', 'Weimar', 'Thueringen');


-- ---------------------------------------------------------------------
-- nutzer (10 Eintraege)
-- Die Nutzer 9 und 10 haben keine Strasse und Hausnummer. Das zeigt,
-- dass diese Angaben optional sind.
-- ---------------------------------------------------------------------
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (1, 'Olivia', 'Jones', 'Olivia.J@email.com', 'hashwert', 'Große Freiheit', '35', '22767');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (2, 'Peter', 'Lustig', 'Peter.L@email.com', 'hashwert', 'Am Pariser Platz', '1', '10115');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (3, 'Hugen', 'Dubel', 'H.Dubel@email.com', 'hashwert', 'Maria-Luiko-Straße', '54', '80636');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (4, 'Lisa', 'Meier', 'L.Meier@email.com', 'hashwert', 'Volkartstraße', '70', '80636');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (5, 'Max', 'Mustermann', 'M.Mustermann@email.com', 'hashwert', 'Schwere-Reiter-Straße', '2h', '80636');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (6, 'Ingo', 'Kretzschmar', 'I.Kretzschmar@email.com', 'hashwert', 'Batheyer Straße', '115-117', '58099');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (7, 'Johann Wolfgang', 'Goethe', 'J.W.Goethe@email.com', 'hashwert', 'Frauenplan', '1', '99423');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (8, 'Friedrich', 'Schiller', 'F.Schiller@email.com', 'hashwert', 'Frauenplan', '2', '99423');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (9, 'Erich', 'Kästner', 'E.Kaestner@email.com', 'hashwert', NULL, NULL, '01067');
INSERT INTO nutzer (nutzer_id, vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl) VALUES (10, 'Siegfried', 'Lenz', 'S.Lenz@email.com', 'hashwert', NULL, NULL, '20457');


-- ---------------------------------------------------------------------
-- sprache (12 Eintraege)
-- Der Auffangwert Sonstiges verhindert, dass Nutzer bei fehlender
-- Sprache eigene Schreibweisen anlegen.
-- ---------------------------------------------------------------------
INSERT INTO sprache (sprach_id, sprache) VALUES (1, 'Deutsch');
INSERT INTO sprache (sprach_id, sprache) VALUES (2, 'Englisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (3, 'Französisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (4, 'Italienisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (5, 'Swahili');
INSERT INTO sprache (sprach_id, sprache) VALUES (6, 'Portugiesisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (7, 'Spanisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (8, 'Arabisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (9, 'Japanisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (10, 'Chinesisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (11, 'Koreanisch');
INSERT INTO sprache (sprach_id, sprache) VALUES (12, 'Sonstiges');


-- ---------------------------------------------------------------------
-- genre (13 Eintraege)
-- Die Liste ist im Betrieb erweiterbar, ohne das Schema zu aendern.
-- Waere sie als CHECK-Liste in buch umgesetzt, waere dafuer ein
-- ALTER TABLE noetig.
-- ---------------------------------------------------------------------
INSERT INTO genre (genre_id, genre) VALUES (1, 'Fantasy');
INSERT INTO genre (genre_id, genre) VALUES (2, 'Krimi');
INSERT INTO genre (genre_id, genre) VALUES (3, 'Horror');
INSERT INTO genre (genre_id, genre) VALUES (4, 'Thriller');
INSERT INTO genre (genre_id, genre) VALUES (5, 'Sci-Fi');
INSERT INTO genre (genre_id, genre) VALUES (6, 'Roman');
INSERT INTO genre (genre_id, genre) VALUES (7, 'Fachbuch');
INSERT INTO genre (genre_id, genre) VALUES (8, 'Jugendbuch');
INSERT INTO genre (genre_id, genre) VALUES (9, 'Reisebuch');
INSERT INTO genre (genre_id, genre) VALUES (10, 'Gedicht');
INSERT INTO genre (genre_id, genre) VALUES (11, 'Kinderbuch');
INSERT INTO genre (genre_id, genre) VALUES (12, 'Sonstige');
INSERT INTO genre (genre_id, genre) VALUES (13, 'Historisch');


-- ---------------------------------------------------------------------
-- autor (12 Eintraege)
-- ---------------------------------------------------------------------
INSERT INTO autor (autor_id, vorname, nachname) VALUES (1, 'Brandon', 'Sanderson');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (2, 'Pierce', 'Brown');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (3, 'Sam', 'Feuerbach');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (4, 'Sebastian', 'Fitzek');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (5, 'Scott', 'Lynch');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (6, 'Arthur Conan', 'Doyle');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (7, 'Ken', 'Follett');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (8, 'Kai', 'Meyer');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (9, 'Robin', 'Hobb');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (10, 'Cornelia', 'Funke');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (11, 'Noah', 'Gordon');
INSERT INTO autor (autor_id, vorname, nachname) VALUES (12, 'Holger', 'Hanowell');


-- ---------------------------------------------------------------------
-- buch (12 Eintraege)
-- ---------------------------------------------------------------------
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9780765326355', 'Way of Kings', 2010, 2);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783453534421', 'Im Haus der Feinde', 2016, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783947515110', 'Les Messieurs de Grandval', 2019, 3);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783426503751', 'Der Augensammler', 2010, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783453530911', 'Die Lügen des Locke Lamora', 2007, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783150207529', 'Eine Studie in Scharlachrot', 1887, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783404259885', 'Die Säulen der Erde', 1990, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783596198535', 'Die Seiten der Welt', 2014, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9780553573398', 'Assassins Apprentice', 1995, 2);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783791504650', 'Tintenherz', 2003, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783453471092', 'Medicus', 1987, 1);
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id) VALUES ('9783492705042', 'Krieger des Feuers', 2018, 1);


-- ---------------------------------------------------------------------
-- buch_genre (18 Eintraege)
-- Sechs Buecher haben zwei Genres. Das belegt die N:M-Beziehung:
-- eine einzelne genre_id-Spalte in buch koennte das nicht abbilden.
-- ---------------------------------------------------------------------
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9780765326355', 1);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783453534421', 5);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783947515110', 1);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783426503751', 4);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783453530911', 1);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783453530911', 2);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783150207529', 6);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783150207529', 2);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783404259885', 6);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783404259885', 13);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783596198535', 1);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783596198535', 8);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9780553573398', 1);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783791504650', 1);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783791504650', 8);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783453471092', 13);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783453471092', 6);
INSERT INTO buch_genre (isbn, genre_id) VALUES ('9783492705042', 1);


-- ---------------------------------------------------------------------
-- buch_autor (13 Eintraege)
-- Autor 1 ist zwei Buechern zugeordnet, Buch 9783150207529 hat zwei
-- Autoren. Damit sind beide Richtungen der N:M-Beziehung belegt.
-- ---------------------------------------------------------------------
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9780765326355', 1);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783492705042', 1);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783453534421', 2);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783947515110', 3);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783426503751', 4);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783453530911', 5);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783150207529', 6);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783150207529', 12);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783404259885', 7);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783596198535', 8);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9780553573398', 9);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783791504650', 10);
INSERT INTO buch_autor (isbn, autor_id) VALUES ('9783453471092', 11);


-- ---------------------------------------------------------------------
-- uebergabeart (2 Eintraege)
-- ---------------------------------------------------------------------
INSERT INTO uebergabeart (art_id, uebergabe) VALUES (1, 'Versand');
INSERT INTO uebergabeart (art_id, uebergabe) VALUES (2, 'Abholung');


-- ---------------------------------------------------------------------
-- exemplar (10 Eintraege)
--
-- WICHTIG: Die Exemplare 9, 15 und 16 sind im laufenden Betrieb
-- verliehen. Sie werden hier dennoch als Verfuegbar angelegt, weil der
-- Trigger trg_verfuegbarkeit sonst die zugehoerigen Ausleihen abweist.
--
-- Archiviert kann dagegen sofort gesetzt werden, da an archivierten
-- Exemplaren keine Ausleihen haengen.
--
-- Das Buch 9780765326355 liegt bei zwei verschiedenen Nutzern
-- (Exemplar 9 und 10). Das belegt die Trennung von Werk und Objekt.
-- ---------------------------------------------------------------------
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (9,  'Verfuegbar', 'Hervorragend', 1,  '9780765326355');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (10, 'Verfuegbar', 'Gut',          4,  '9780765326355');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (11, 'Verfuegbar', 'Schlecht',     1,  '9783492705042');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (12, 'Archiviert', 'Schlecht',     2,  '9783426503751');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (13, 'Verfuegbar', 'Gut',          3,  '9783453530911');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (14, 'Archiviert', 'Hervorragend', 10, '9783150207529');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (15, 'Verfuegbar', 'Gut',          6,  '9783404259885');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (16, 'Verfuegbar', 'Hervorragend', 6,  '9783596198535');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (17, 'Archiviert', 'Schlecht',     6,  '9783596198535');
INSERT INTO exemplar (exemplar_id, status, zustand, nutzer_id, isbn) VALUES (18, 'Verfuegbar', 'Gut',          7,  '9783453471092');


-- ---------------------------------------------------------------------
-- anfrage (11 Eintraege)
-- Exemplar 13 wird dreimal angefragt, mit je unterschiedlichem Status.
-- Das zeigt, warum die Anfrage als eigene Entitaet modelliert ist:
-- mehrere Nutzer koennen um dasselbe Exemplar konkurrieren.
-- Kein Nutzer fragt sein eigenes Exemplar an.
-- ---------------------------------------------------------------------
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (1,  'Angenommen', 5,  9,  1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (2,  'Angenommen', 8,  10, 1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (3,  'Angenommen', 2,  13, 1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (4,  'Angenommen', 9,  15, 1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (5,  'Angenommen', 3,  16, 1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (6,  'Gestellt',   1,  18, 1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (7,  'Gestellt',   4,  11, 1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (8,  'Gestellt',   10, 13, 1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (9,  'Abgelehnt',  7,  9,  1);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (10, 'Abgelehnt',  4,  13, 2);
INSERT INTO anfrage (anfrage_id, status, nutzer_id, exemplar_id, art_id) VALUES (11, 'Abgelehnt',  3,  10, 2);


-- ---------------------------------------------------------------------
-- ausleihe (13 Eintraege)
-- Zehn abgeschlossene und drei laufende Ausleihen.
-- Die Ausleihen 5 und 9 wurden verspaetet zurueckgegeben: vereinbart
-- waren 14 Tage, tatsaechlich vergingen 21.
-- Exemplar 9 wurde dreimal verliehen, ohne dass sich die Zeitraeume
-- ueberschneiden. Die Historie liegt in ausleihe, der aktuelle Zustand
-- in exemplar.
-- ---------------------------------------------------------------------
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (1,  '2026-02-14', '2026-02-28', 14, 10, 9,  1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (2,  '2026-03-05', '2026-03-26', 21, 9,  18, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (3,  '2026-04-10', '2026-04-24', 14, 2,  9,  1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (4,  '2026-05-02', '2026-05-16', 14, 5,  11, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (5,  '2026-05-20', '2026-06-10', 14, 1,  15, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (6,  '2026-06-01', '2026-06-15', 14, 8,  13, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (7,  '2026-06-12', '2026-06-26', 14, 4,  16, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (8,  '2026-07-01', '2026-07-15', 14, 3,  10, 2);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (9,  '2026-07-15', '2026-08-05', 14, 2,  13, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (10, '2026-08-10', '2026-08-24', 14, 8,  10, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (11, '2026-09-20', NULL,         21, 5,  9,  1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (12, '2026-09-28', NULL,         14, 9,  15, 1);
INSERT INTO ausleihe (ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id) VALUES (13, '2026-10-01', NULL,         28, 3,  16, 1);


-- ---------------------------------------------------------------------
-- bewertung (10 Eintraege)
-- Bewertet werden koennen nur die abgeschlossenen Ausleihen 1 bis 10.
-- Vier Bewertungen haben keinen Kommentar, die Spalte ist optional.
-- Die Sterne reichen von 1 bis 5.
-- ---------------------------------------------------------------------
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (1,  5, 'Perfekter Zustand des Buches, schnelle Abwicklung', 1);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (2,  4, 'Buch war im guten Zustand, Versand problemlos', 2);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (3,  5, NULL, 3);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (4,  1, 'Zustand des Buches war sehr schlecht', 4);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (5,  4, 'Buch war gut. Ausleiher war tolerant obwohl ich das Buch länger ausgeliehen hatte', 5);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (6,  4, NULL, 6);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (7,  5, NULL, 7);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (8,  4, 'Zustand des Buchs gut. Abholung problemlos', 8);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (9,  2, 'Versand hat lange gedauert, Verpackung war beschaedigt', 9);
INSERT INTO bewertung (bewertung_id, sterne, kommentar, ausleih_id) VALUES (10, 5, NULL, 10);



-- =====================================================================
-- TEIL 5: SEQUENZEN
--
-- Die Schluesselwerte wurden oben ausdruecklich vergeben. Die Zaehler
-- der SERIAL-Spalten stehen deshalb noch auf dem Anfangswert und werden
-- hier auf den aktuellen Stand gesetzt. Ohne diesen Schritt wuerde der
-- naechste INSERT ohne Schluesselangabe mit einem bereits vergebenen
-- Wert kollidieren.
-- =====================================================================
SELECT pg_catalog.setval('nutzer_nutzer_id_seq',       10, true);
SELECT pg_catalog.setval('sprache_sprach_id_seq',      12, true);
SELECT pg_catalog.setval('genre_genre_id_seq',         13, true);
SELECT pg_catalog.setval('autor_autor_id_seq',         12, true);
SELECT pg_catalog.setval('uebergabeart_art_id_seq',     2, true);
SELECT pg_catalog.setval('exemplar_exemplar_id_seq',   18, true);
SELECT pg_catalog.setval('anfrage_anfrage_id_seq',     11, true);
SELECT pg_catalog.setval('ausleihe_ausleih_id_seq',    13, true);
SELECT pg_catalog.setval('bewertung_bewertung_id_seq', 10, true);


-- =====================================================================
-- ENDE