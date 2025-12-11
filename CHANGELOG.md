# Endringslogg

Alle vesentlige endringer i dette prosjektet dokumenteres her.

## [1.1.0] - 2025-12-11

### Bakgrunn

Martin Flatø (FHI) påpekte at mestringsnivågrensene vi opprinnelig brukte (hentet fra Udirs dokumentasjon) ikke stemte overens med de faktiske grensene som historisk har blitt brukt i klassifiseringen. Dette motiverte en empirisk analyse for å identifisere de faktiske grensene direkte fra registerdata.

### Lagt til

- **Empirisk grenseidentifisering** (`R/threshold_identification.R`)
  - Identifiserer eksakte grenser fra klassifiseringsgrenser i registerdata
  - Validerer kalibrering mot Udirs dokumenterte prosentilfordeling
  - Genererer omfattende dokumentasjon i `output/threshold_identification/`

- **Persentilkalibreringsfigur**
  - Viser mål- vs. faktiske persentiler for førstegangsterskler
  - Bekrefter at grensene ble satt i henhold til 25–50–25 og 10–20–40–20–10 fordeling

- **Utvidet dokumentasjon i README**
  - Komplett grensetigtabeller for alle fag og trinn
  - Dokumentert 2014 empiriske verdier
  - Klargjort klassifiseringsregel (poengsum ≥ grense → høyere nivå)
  - Lenke til [Udirs rammeverk](https://www.udir.no/eksamen-og-prover/prover/rammeverk-for-nasjonale-prover2/gjennomforing-og-resultater/)
  - Forklaring av metodologisk valg om konstante grenser

### Endret

- **Oppdaterte mestringsnivågrenser i config.R**
  - Tidligere: Tilnærmede verdier fra Udir-dokumentasjon
  - Nå: Empirisk verifiserte 2014-verdier fra registerdata
  - Hovedendringer:
    - 5. trinn: Alle fag bruker nå identiske grenser (42.5, 56.5)
    - 8. trinn: Fagspesifikke grenser basert på empirisk evidens
    - Regning 8. trinn: Korrigert fra (37, 44, 54, 62) til (37.0, 45.0, 55.0, 63.0)

- **Forbedret kodedokumentasjon**
  - Detaljerte kommentarer i config.R om grensekilde og metodologi
  - Dokumentert målfordelinger per trinn

- **Rettet hardkodede grenser i generate_report.R**
  - Bruker nå sentralisert `get_cutoffs()` i stedet for lokale verdier

### Dokumentert

- **Grenseendringer over tid (2014–2021)**
  - Regning 8. trinn: Heltallsgrenser i 2014, X.5-format fra 2015
  - Lesing 5. trinn: Grense 2→3 økt fra 56.5 til 57.5 fra 2016
  - Lesing 8. trinn: Flere grenseendringer (se threshold_report for detaljer)
  - Engelsk: Konsistente grenser alle år (begge trinn)

- **Dataperiode og ekskluderinger**
  - Analysen dekker 2014–2021
  - 2022 ekskludert grunnet heltallsformat (ulikt regime)

### Tekniske merknader

- Hovedanalysen bruker 2014-grenser konsekvent for alle år
- Dette muliggjør ren sammenligning av korreksjonseffekter uten konfundering fra grenseendringer
- Kan avvike marginalt fra Udirs offisielle klassifiseringer i år der grenser faktisk ble endret
- Verifisering viser >99.9% samsvar mellom beregnede og faktiske nivåtildelinger
- Se `output/threshold_identification/threshold_report.pdf` for fullstendig dokumentasjon

### Takk

Takk til Martin Flatø (FHI) for å ha oppdaget avviket mellom dokumenterte og faktiske grenser, som motiverte denne forbedringen.

---

## [1.0.0] - 2025-12-05

### Første versjon

- Implementert poengkorrigering basert på SSBs omskaleringsparametre
- Mestringsnivåtildeling med grenser fra Udir-dokumentasjon
- Verifiseringsanalyse mot originaldata
- Avviksvisualisering og sammendragsplott
- PDF-rapportgenerering
