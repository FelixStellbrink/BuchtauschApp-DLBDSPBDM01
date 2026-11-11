README

# BuchtauschApp-DLBDSPBDM01
Datenbank für eine Buchtausch-App. Erstellt für das Projekt des Kurses DLBDSPBDM01 an der IU Internationalen Hochschule. 

## Inhalt
```
├── 01_Konzeptionsphase
│   └── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Konzeptionsphase_AB.pdf
├── 02_Erarbeitungs-Reflexionsphase
│   ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Erarbeitungs-Reflexionsphase_KZ.pdf
│   ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Erarbeitungs-Reflexionsphase_PR.pdf
│   ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Erarbeitungs-Reflexionsphase_SQL_Abfragen.sql
│   ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Erarbeitungs-Reflexionsphase_SQL_Installation.sql
│   └── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Erarbeitungs-Reflexionsphase_SQL_Testfaelle.sql
└── 03_Finalisierungsphase
    ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_AB.pdf
    ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_BE.pdf
    ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_GH.pdf
    ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_SQL.pdf
    ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_SQL_Abfragen.sql
    ├── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_SQL_Installation.sql
    └── Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_SQL_Testfaelle.sql
```
## Voraussetzungen
Die Datenbank wurde mit PostgreSQL 18.3 umgesetzt und in pgAdmin 4 (Version 9.16) getestet.

## Installation
Als Erstes muss die Datenbank mit `CREATE DATABASE buchtausch;` angelegt werden.
Danach muss man sich mit ihr verbinden. Erst dann kann das Installationsskript (Stellbrink-Felix_IU14127320_DLBDSPBDM01_D_Finalisierungsphase_SQL_Installation.sql) ausgeführt werden. Dieses Skript muss vollständig ausgeführt werden, damit die Testfälle und Abfragen funktionieren. 

## Testfälle und Abfragen
Insgesamt existieren 20 negative Testfälle und 10 positive Testfälle. Die Testfälle müssen einzeln ausgeführt werden, da jeder negative Testlauf absichtlich scheitert. Sobald das erste fehlerhafte Statement ausgeführt wird, bricht die Ausführung ab. Die negativen Testfälle verändern keine Daten, da sie von der Datenbank abgewiesen werden.
P10 verändert als einziger Testfall Daten. Daher sollte nach der Ausführung dieses Testfalls das Installationsskript erneut ausgeführt werden. 
Die Abfragen verändern keine Daten, sondern zeigen nur, welche Fragen mit der Datenbank beantwortet werden können. 

## Verfasser
Felix Stellbrink, IU14127320, DLBDSPBDM01
