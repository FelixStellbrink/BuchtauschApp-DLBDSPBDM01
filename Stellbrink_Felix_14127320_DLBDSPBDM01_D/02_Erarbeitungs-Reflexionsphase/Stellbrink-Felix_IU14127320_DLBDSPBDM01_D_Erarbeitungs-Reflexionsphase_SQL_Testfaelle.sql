-- =====================================================================
-- Buchtausch-App - Testfaelle
-- Portfolio DLBDSPBDM01_D, Phase 2
--
-- WICHTIG: Diese Datei wird NICHT am Stueck ausgefuehrt.
-- Die negativen Testfaelle scheitern absichtlich. Sobald das erste
-- Statement einen Fehler wirft, bricht die Ausfuehrung ab.
-- Jeden Testfall einzeln markieren und ausfuehren.
--
-- Voraussetzung: Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Erarbeitungs-Reflexionsphase_SQL_Installation
-- wurde vollstaendig ausgefuehrt
-- Die negativen Testfaelle veraendern den Datenbestand nicht, da sie
-- alle abgewiesen werden.
-- P10 ist der einzige Testfall, der den Datenbestand aendert.
--
-- Aufbau:
--   Teil 1  Negative Testfaelle (T1 bis T20)
--   Teil 2  Positive Testfaelle (P1 bis P10)
--   Teil 3  Datenbestand
-- =====================================================================


-- =====================================================================
-- TEIL 1: NEGATIVE TESTFAELLE
-- Jedes Statement muss abgewiesen werden.
-- =====================================================================

-- ---------------------------------------------------------------------
-- T1: ort, negativ
-- Regel: PRIMARY KEY (postleitzahl)
-- Erwartet: ERROR 23505, Constraint ort_pkey
-- Die PLZ 22767 ist bereits vergeben.
-- ---------------------------------------------------------------------
INSERT INTO ort (postleitzahl, stadt, bundesland)
VALUES ('22767', 'Hamburg', 'Hamburg');


-- ---------------------------------------------------------------------
-- T2: nutzer, negativ
-- Regel: CHECK (email LIKE '%@%')
-- Erwartet: ERROR 23514, Constraint nutzer_email_check
-- Die Adresse enthaelt kein @.
-- ---------------------------------------------------------------------
INSERT INTO nutzer (vorname, nachname, email, passwort_hash, strasse, hausnummer, postleitzahl)
VALUES ('Peter', 'Maffai', 'P.Maffai.com', 'hashwert', 'Musterstrasse', '1a', '01067');


-- ---------------------------------------------------------------------
-- T3: sprache, negativ
-- Regel: UNIQUE (sprache)
-- Erwartet: ERROR 23505, Constraint sprache_sprache_key
-- Deutsch ist bereits angelegt.
-- ---------------------------------------------------------------------
INSERT INTO sprache (sprache)
VALUES ('Deutsch');


-- ---------------------------------------------------------------------
-- T4: genre, negativ
-- Regel: FOREIGN KEY buch_genre.genre_id -> genre.genre_id
-- Erwartet: ERROR 23503, Constraint buch_genre_genre_id_fkey
-- Fantasy ist mehreren Buechern zugeordnet und kann deshalb nicht
-- geloescht werden. Der Fremdschluessel schuetzt nicht nur beim
-- Einfuegen, sondern auch beim Loeschen der referenzierten Zeile.
-- ---------------------------------------------------------------------
DELETE FROM genre WHERE genre = 'Fantasy';


-- ---------------------------------------------------------------------
-- T5: autor, negativ
-- Regel: FOREIGN KEY buch_autor.autor_id -> autor.autor_id
-- Erwartet: ERROR 23503, Constraint buch_autor_autor_id_fkey
-- Fitzek ist dem Augensammler zugeordnet.
-- Die Tabelle autor hat bewusst kein UNIQUE, da Namensgleichheit
-- moeglich ist. Der zeigenswerte Fall ist deshalb das Loeschen.
-- ---------------------------------------------------------------------
DELETE FROM autor WHERE nachname = 'Fitzek';


-- ---------------------------------------------------------------------
-- T6: buch, negativ
-- Regel: FOREIGN KEY buch.sprach_id -> sprache.sprach_id
-- Erwartet: ERROR 23503, Constraint buch_sprach_id_fkey
-- Die Sprache 76 existiert nicht.
-- ---------------------------------------------------------------------
INSERT INTO buch (isbn, titel, erscheinungsjahr, sprach_id)
VALUES ('9876543210123', 'Testfaelle', 2023, 76);


-- ---------------------------------------------------------------------
-- T7: buch_genre, negativ
-- Regel: PRIMARY KEY (isbn, genre_id)
-- Erwartet: ERROR 23505, Constraint buch_genre_pkey
-- Die Kombination existiert bereits. Ein Buch kann mehrere Genres
-- haben, aber dasselbe Genre nur einmal.
-- ---------------------------------------------------------------------
INSERT INTO buch_genre (isbn, genre_id)
VALUES ('9783453530911', 2);


-- ---------------------------------------------------------------------
-- T8: buch_autor, negativ
-- Regel: PRIMARY KEY (isbn, autor_id)
-- Erwartet: ERROR 23505, Constraint buch_autor_pkey
-- Die Kombination existiert bereits.
-- ---------------------------------------------------------------------
INSERT INTO buch_autor (isbn, autor_id)
VALUES ('9780765326355', 1);


-- ---------------------------------------------------------------------
-- T9: uebergabeart, negativ
-- Regel: CHECK (uebergabe IN ('Abholung', 'Versand'))
-- Erwartet: ERROR 23514, Constraint uebergabeart_uebergabe_check
-- Die Wertemenge ist abgeschlossen, ein dritter Wert nicht erlaubt.
-- ---------------------------------------------------------------------
INSERT INTO uebergabeart (uebergabe)
VALUES ('Flugzeug');


-- ---------------------------------------------------------------------
-- T10: exemplar, negativ
-- Regel: CHECK (status IN ('Verfuegbar', 'Verliehen', 'Archiviert'))
-- Erwartet: ERROR 23514, Constraint exemplar_status_check
-- Kaputt ist kein zulaessiger Status.
-- ---------------------------------------------------------------------
INSERT INTO exemplar (status, zustand, nutzer_id, isbn)
VALUES ('Kaputt', 'Schlecht', 3, '9783596198535');


-- ---------------------------------------------------------------------
-- T11: anfrage, negativ
-- Regel: CHECK (status IN ('Gestellt', 'Angenommen', 'Abgelehnt'))
-- Erwartet: ERROR 23514, Constraint anfrage_status_check
-- Vielleicht ist kein zulaessiger Status.
-- ---------------------------------------------------------------------
INSERT INTO anfrage (status, nutzer_id, exemplar_id, art_id)
VALUES ('Vielleicht', 1, 10, 1);


-- ---------------------------------------------------------------------
-- T12: bewertung, negativ
-- Regel: CHECK (sterne BETWEEN 1 AND 5)
-- Erwartet: ERROR 23514, Constraint bewertung_sterne_check
-- Die Skala endet bei fuenf Sternen, sechs sind nicht zulaessig.
-- Der CHECK reicht hier aus, weil der Wert in derselben Zeile steht.
-- ---------------------------------------------------------------------
INSERT INTO bewertung (sterne, kommentar, ausleih_id)
VALUES (6, NULL, 10);


-- ---------------------------------------------------------------------
-- T13: ausleihe, negativ
-- Regel: CHECK (startdatum <= enddatum)
-- Erwartet: ERROR 23514, Constraint ausleihe_check
-- Das Enddatum liegt vier Tage vor dem Startdatum.
-- Der CHECK steht auf Tabellenebene, weil er zwei Spalten derselben
-- Zeile vergleicht. Ein Spalten-CHECK kann das nicht.
-- ---------------------------------------------------------------------
INSERT INTO ausleihe (startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id)
VALUES ('2026-08-12', '2026-08-08', 14, 3, 3, 1);


-- ---------------------------------------------------------------------
-- T14: bewertung, negativ
-- Regel: TRIGGER trg_bewertung
-- Erwartet: ERROR P0001, 'Ausleihe 12 ist noch nicht beendet, Bewertung nicht moeglich'
-- Ausleihe 12 laeuft noch, das enddatum ist NULL.
-- Auch hier liegen die geprueften Informationen in einer anderen Tabelle.
-- ---------------------------------------------------------------------
INSERT INTO bewertung (sterne, kommentar, ausleih_id)
VALUES (4, NULL, 12);


-- ---------------------------------------------------------------------
-- T15: bewertung, negativ
-- Regel: TRIGGER trg_bewertung
-- Erwartet: ERROR P0001, 'Ausleihe 11 ist noch nicht beendet, Bewertung nicht moeglich'
-- Ausleihe 11 laeuft noch, das enddatum ist NULL.
-- Hier wird keine neue Bewertung angelegt, sondern eine bestehende geaendert. 
-- ---------------------------------------------------------------------

UPDATE bewertung SET ausleih_id=11
WHERE bewertung_id=1;

-- ---------------------------------------------------------------------
-- T16: ausleihe, negativ
-- Regel: TRIGGER trg_verfuegbarkeit
-- Erwartet: ERROR P0001, 'Exemplar 9 ist nicht verfuegbar.'
-- Exemplar 9 ist seit dem 20.09. verliehen (Ausleihe 11).
-- Ein CHECK kann das nicht pruefen, da der Status in exemplar steht
-- und nicht in ausleihe. Dafuer ist der Trigger noetig.
-- ---------------------------------------------------------------------
INSERT INTO ausleihe (startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id, art_id)
VALUES ('2026-09-28', NULL, 19, 2, 9, 2);

-- ---------------------------------------------------------------------
-- T17: anfrage, negativ
-- Regel: TRIGGER trg_anfrage
-- Erwartet: ERROR P0001, 'Nutzer 4 besitzt dieses Exemplar.'
-- Exemplar 10 besitzt der Nutzer 4.
-- Ein CHECK kann das nicht pruefen, da der nutzer von anfrage mit 
-- nutzer von exemplar verglichen werden muss. Dafuer ist der Trigger noetig.
-- ---------------------------------------------------------------------

INSERT INTO anfrage (status, nutzer_id, exemplar_id, art_id)
VALUES
('Gestellt',4,10,1);


-- ---------------------------------------------------------------------
-- T18: anfrage, negativ
-- Regel: TRIGGER trg_anfrage
-- Erwartet: ERROR P0001, 'Nutzer 4 besitzt dieses Exemplar.'
-- Anfrage stammt von Nutzer 4 und wird auf Exemplar 10 umgeleitet, welches Nutzer 4 besitzt.
-- Der Trigger faengt auch UPDATE ab.
-- ---------------------------------------------------------------------

UPDATE anfrage SET exemplar_id=10 WHERE anfrage_id=7;


-- ---------------------------------------------------------------------
-- T19: ausleihe, negativ
-- Regel: UNIQUE INDEX ausleihe_aktiv
-- Erwartet: ERROR 23505, ausleihe_aktiv
-- Index verhindert, dass zwei aktive Ausleihen auf demselben Exemplar existieren.
-- ---------------------------------------------------------------------

UPDATE ausleihe SET enddatum = NULL WHERE ausleih_id=1;


-- ---------------------------------------------------------------------
-- T20: anfrage, negativ
-- Regel: UNIQUE INDEX anfrage_angenommen
-- Erwartet: ERROR 23505, anfrage_angenommen
-- Index verhindert, dass zwei angenommene Anfragen auf dasselbe Exemplar existieren.
-- ---------------------------------------------------------------------

UPDATE anfrage SET status='Angenommen' WHERE anfrage_id=8;




-- =====================================================================
-- TEIL 2: POSITIVE TESTFAELLE
-- Jedes Statement muss ein Ergebnis liefern.
-- =====================================================================

-- ---------------------------------------------------------------------
-- P1: ort, positiv
-- Zeigt: CHAR(5) erhaelt die fuehrende Null.
-- Bei INT stuende hier 1067, die Postleitzahl waere falsch.
-- Die zweite Spalte macht den Unterschied sichtbar.
-- ---------------------------------------------------------------------
SELECT postleitzahl, CAST(postleitzahl AS INT) AS als_zahl, stadt
FROM ort
WHERE postleitzahl = '01067';


-- ---------------------------------------------------------------------
-- P2: nutzer, positiv
-- Zeigt: strasse und hausnummer sind optional.
-- Die Angaben werden erst beim Versand benoetigt, die Postleitzahl
-- dagegen immer fuer die Filterung.
-- ---------------------------------------------------------------------
SELECT nutzer_id, vorname, nachname, strasse, hausnummer, postleitzahl
FROM nutzer
WHERE strasse IS NULL;


-- ---------------------------------------------------------------------
-- P3: sprache, positiv
-- Zeigt: Auffangwert fuer Sprachen ausserhalb der Liste.
-- ---------------------------------------------------------------------
SELECT sprach_id, sprache
FROM sprache
WHERE sprache = 'Sonstiges';


-- ---------------------------------------------------------------------
-- P4: buch_genre, positiv
-- Zeigt: Ein Buch mit zwei gleichrangigen Genres.
-- Mit einer einzelnen genre_id-Spalte in buch waere das nicht
-- abbildbar. Das ist der Grund fuer die Ueberfuehrungstabelle.
-- ---------------------------------------------------------------------
SELECT b.titel, g.genre
FROM buch b
JOIN buch_genre bg ON b.isbn = bg.isbn
JOIN genre g       ON bg.genre_id = g.genre_id
WHERE b.isbn = '9783453530911';


-- ---------------------------------------------------------------------
-- P5: buch_autor, positiv
-- Zeigt: Beide Richtungen der N:M-Beziehung.
-- Sanderson ist zwei Buechern zugeordnet, die Studie in Scharlachrot
-- hat zwei Autoren.
-- ---------------------------------------------------------------------
SELECT a.vorname, a.nachname, b.titel
FROM autor a
JOIN buch_autor ba ON a.autor_id = ba.autor_id
JOIN buch b        ON ba.isbn = b.isbn
WHERE a.autor_id = 1 OR b.isbn = '9783150207529'
ORDER BY a.nachname, b.titel;


-- ---------------------------------------------------------------------
-- P6: exemplar, positiv
-- Zeigt: Dasselbe Buch bei zwei verschiedenen Nutzern, in
-- unterschiedlichem Zustand. Das ist der Grund fuer die Trennung von
-- Werk (buch) und Objekt (exemplar).
-- ---------------------------------------------------------------------
SELECT e.exemplar_id, e.status, e.zustand, e.nutzer_id, b.titel
FROM exemplar e
JOIN buch b ON e.isbn = b.isbn
WHERE e.isbn = '9780765326355';


-- ---------------------------------------------------------------------
-- P7: anfrage, positiv
-- Zeigt: Drei Anfragen auf dasselbe Exemplar mit unterschiedlichem
-- Status. Mehrere Nutzer koennen um ein Exemplar konkurrieren, der
-- Besitzer entscheidet. Deshalb ist die Anfrage eine eigene Entitaet
-- und nicht Teil der Ausleihe.
-- ---------------------------------------------------------------------
SELECT anfrage_id, status, nutzer_id, exemplar_id, art_id
FROM anfrage
WHERE exemplar_id = 13
ORDER BY anfrage_id;


-- ---------------------------------------------------------------------
-- P8: bewertung, positiv
-- Zeigt: kommentar ist optional, die Sterne sind Pflicht.
-- ---------------------------------------------------------------------
SELECT bewertung_id, sterne, kommentar, ausleih_id
FROM bewertung
WHERE kommentar IS NULL
ORDER BY bewertung_id;

-- ---------------------------------------------------------------------
-- P9: ausleihe, positiv
-- Zeigt: Laufende Ausleihen haben kein enddatum. Der Nullwert
-- bedeutet hier "noch nicht zurueckgegeben" und ist der einzige
-- Datums-Nullwert im Schema.
-- ---------------------------------------------------------------------
SELECT ausleih_id, startdatum, enddatum, ausleihdauer, nutzer_id, exemplar_id
FROM ausleihe
WHERE enddatum IS NULL
ORDER BY ausleih_id;

-- ---------------------------------------------------------------------
-- P10: Trigger setze_status, positiv
-- Zeigt: status wird automatisch angepasst, nach dem Setzen des enddatums 
-- CAVE: beim ausfuehren dieses Testfalls werden Daten in der Datenbank geaendert.
-- ---------------------------------------------------------------------
UPDATE ausleihe SET enddatum = '2026-10-16' WHERE ausleih_id = 11;
SELECT exemplar_id, status FROM exemplar WHERE exemplar_id = 9;


-- =====================================================================
-- TEIL 3: DATENBESTAND
-- Nachweis, dass jede Tabelle mindestens zehn Eintraege hat.
-- Ausnahme uebergabeart: die Wertemenge ist mit Abholung und Versand
-- fachlich abgeschlossen.
-- =====================================================================
SELECT 'ort' AS tabelle, COUNT(*) AS eintraege FROM ort
UNION ALL SELECT 'nutzer',       COUNT(*) FROM nutzer
UNION ALL SELECT 'sprache',      COUNT(*) FROM sprache
UNION ALL SELECT 'genre',        COUNT(*) FROM genre
UNION ALL SELECT 'autor',        COUNT(*) FROM autor
UNION ALL SELECT 'buch',         COUNT(*) FROM buch
UNION ALL SELECT 'buch_genre',   COUNT(*) FROM buch_genre
UNION ALL SELECT 'buch_autor',   COUNT(*) FROM buch_autor
UNION ALL SELECT 'uebergabeart', COUNT(*) FROM uebergabeart
UNION ALL SELECT 'exemplar',     COUNT(*) FROM exemplar
UNION ALL SELECT 'anfrage',      COUNT(*) FROM anfrage
UNION ALL SELECT 'ausleihe',     COUNT(*) FROM ausleihe
UNION ALL SELECT 'bewertung',    COUNT(*) FROM bewertung
ORDER BY tabelle;


-- =====================================================================
-- Zusaetzliche Pruefung: Konsistenz von Status und Ausleihen.
-- Jedes Exemplar mit Status Verliehen muss genau eine laufende
-- Ausleihe haben, alle anderen keine.
-- =====================================================================
SELECT e.exemplar_id, e.status,
       (SELECT COUNT(*) FROM ausleihe a
        WHERE a.exemplar_id = e.exemplar_id AND a.enddatum IS NULL) AS offene_ausleihen
FROM exemplar e
ORDER BY e.exemplar_id;