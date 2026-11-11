-- =====================================================================
-- Buchtausch-App - Abfragen
-- Portfolio DLBDSPBDM01_D, Phase 3
--
-- Diese Datei enthaelt Auswertungen, keine Testfaelle. Sie zeigen,
-- welche Fragen sich beispielhaft mit dem Datenmodell beantworten lassen.
-- Alle Abfragen lesen nur und veraendern den Datenbestand nicht.
--
-- Voraussetzung: Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_SQL_Installation
-- wurde vollstaendig ausgefuehrt.
--
-- Aufbau:
--   A1  Laufende Ausleihen je Nutzer
--   A2  Ueberfaellige Ausleihen
--   A3  Durchschnittliche Bewertung je Verleiher
--   A4  Verfuegbare Buecher nach Genre und Standort
-- =====================================================================


-- ---------------------------------------------------------------------
-- A1: Laufende Ausleihen je Nutzer
-- Tabellen: nutzer, ausleihe
-- Zeigt jeden Nutzer mit der Anzahl der Buecher, die er gerade
-- ausgeliehen hat.
-- LEFT JOIN, damit auch Nutzer ohne laufende Ausleihe erscheinen.
-- Die Bedingung auf enddatum steht in der ON-Klausel. 
-- COUNT zaehlt ausleih_id statt *, weil * die Zeile mit den Nullwerten
-- mitzaehlen und jedem Nutzer mindestens 1 geben wuerde.
-- ---------------------------------------------------------------------

SELECT n.nachname,n.vorname, COUNT(a.ausleih_id) AS aktive_ausleihen
FROM nutzer n 
LEFT JOIN ausleihe a ON n.nutzer_id=a.nutzer_id AND a.enddatum IS NULL
GROUP BY n.nutzer_id, n.nachname, n.vorname
ORDER BY aktive_ausleihen DESC, n.nachname;

-- ---------------------------------------------------------------------
-- A2: Ueberfaellige Ausleihen
-- Tabellen: nutzer, ausleihe, exemplar, buch
-- Zeigt alle laufenden Ausleihen, bei denen die vereinbarte Dauer
-- abgelaufen ist, das Buch aber noch nicht zurueckgegeben wurde.
-- Vier Tabellen, weil neben der Ausleihe auch der Name des Ausleihers
-- und der Titel des Buches angezeigt werden sollen.
-- Die erste WHERE-Bedingung beschraenkt auf laufende Ausleihen, die
-- zweite auf solche, deren Faelligkeitsdatum vor dem heutigen Tag
-- liegt. Sortiert wird nach Faelligkeit, damit die am laengsten
-- ueberfaellige Ausleihe oben steht.
-- ---------------------------------------------------------------------

SELECT b.titel, n.nachname, n.vorname, a.startdatum, a.ausleihdauer, 
a.startdatum + a.ausleihdauer AS faellig_am
FROM nutzer n 
JOIN ausleihe a  ON n.nutzer_id=a.nutzer_id
JOIN exemplar e ON a.exemplar_id=e.exemplar_id
JOIN buch b ON e.isbn=b.isbn
WHERE a.enddatum IS NULL AND a.startdatum +a.ausleihdauer<CURRENT_DATE
ORDER BY faellig_am;


-- ---------------------------------------------------------------------
-- A3: Durchschnittliche Bewertung je Verleiher
-- Tabellen: bewertung, ausleihe, exemplar, nutzer
-- Zeigt fuer jeden Nutzer, der Buecher verleiht, den Durchschnitt der
-- Sterne und die Anzahl der Bewertungen.
-- Vier Tabellen, weil die Bewertung an Ausleihe haengt, die Ausleihe an 
-- Exemplar, das Exemplar an dem Nutzer. 
-- Wichtig ist der letzte JOIN, ausleihe und exemplar haben die Spalte
-- nutzer_id, aber es sind unterschiedliche Personen. In Ausleihe 
-- der Ausleiher und in exemplar der Besitzer. Bewertet wird der Besitzer,
-- daher der Join ueber e.nutzer_id.
-- Die Anzahl wird mit ausgegeben, weil ein Durchschnitt aus einer
-- einzelnen Bewertung wenig aussagt.
-- ---------------------------------------------------------------------

SELECT n.nachname, n.vorname, ROUND(AVG(b.sterne),2) AS sterne_durchschnitt,
COUNT(b.bewertung_id) AS anzahl_bewertungen
FROM bewertung b 
JOIN ausleihe a ON b.ausleih_id=a.ausleih_id
JOIN exemplar e ON a.exemplar_id=e.exemplar_id
JOIN nutzer n ON e.nutzer_id=n.nutzer_id
GROUP BY n.nutzer_id
ORDER BY sterne_durchschnitt DESC , anzahl_bewertungen DESC, n.nachname;


-- ---------------------------------------------------------------------
-- A4: Verfuegbare Buecher nach Genre und Standort
-- Tabellen: exemplar, buch, buch_genre, genre, nutzer, ort
-- Zeigt alle verfuegbaren Exemplare mit Titel, Genre, Besitzer und 
-- Standort, sortiert nach Postleitzahl und Titel.
-- Sechs Tabellen, weil Exemplar in zwei Richtungen zeigt: 
-- zu buch, buch_genre und genre fuer das Buch selbst,
-- sowie zu nutzer und ort, um zu zeigen, wo das Exemplar liegt. 
-- STRING_AGG fasst die Genres zusammen, damit Buecher mit mehreren Genres
-- nicht mehrfach aufgelistet werden.
-- Die Postleitzahl gruppiert nach Ort, berechnet aber keine Entfernungen. 
-- ---------------------------------------------------------------------

SELECT b.titel, n.nachname, n.vorname, o.postleitzahl, o.stadt,
STRING_AGG(g.genre, ', ' ORDER BY g.genre) AS genres
FROM exemplar e 
JOIN buch b ON e.isbn=b.isbn
JOIN buch_genre bg ON b.isbn=bg.isbn
JOIN genre g ON bg.genre_id=g.genre_id
JOIN nutzer n ON e.nutzer_id=n.nutzer_id
JOIN ort o ON n.postleitzahl=o.postleitzahl
WHERE e.status='Verfuegbar'
GROUP BY b.isbn, n.nutzer_id, o.postleitzahl, e.exemplar_id
ORDER BY o.postleitzahl, b.titel;

