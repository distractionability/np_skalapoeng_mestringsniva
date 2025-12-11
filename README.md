# Korrigering av nasjonale prøveresultater

R-kode for å korrigere feilaktige skalapoeng fra nasjonale prøver (2014-2021) og analysere effekten på mestringsnivåklassifisering.

## Bakgrunn

Skalapoengene fra nasjonale prøver hadde en feil i beregningen som førte til at spredningen (standardavviket) gradvis ble underestimert over tid. Feilen ble oppdaget og dokumentert i Markussen mfl. (2024) ["Skoleferdigheter i endring: Utviklingen over tid målt ved nasjonale prøver"](https://journals.uio.no/adnorden/article/view/10310/8987), *Acta Didactica Norden*, 18(1). SSB har publisert omskaleringsparametre for å korrigere poengene. Denne koden bruker disse parametrene og viser hvor mange elever som ble feilklassifisert til feil mestringsnivå.

## Filstruktur

```
.
├── R/                              # Aktiv kodebase
│   ├── config.R                    # Konfigurasjon og omskaleringsparametre
│   ├── correction_functions.R      # Funksjoner for poengkorrigering
│   ├── mastery_levels.R            # Mestringsnivåtildeling
│   ├── generate_report.R           # Hovedskript - genererer PDF-rapport
│   ├── verification_analysis.R     # Verifisering mot originaldata
│   ├── discrepancy_ranges.R        # Beregner avviksintervaller
│   ├── discrepancy_visualization.R # Visualisering av avvik
│   ├── shift_summary_plot.R        # Sammendragsplott for nivåendringer
│   └── threshold_identification.R  # Empirisk identifisering av grenser
├── data/
│   ├── npole.dta                   # Hoveddatasett (Stata-format)
│   └── rescaling_parameters.csv    # SSBs omskaleringsparametre (Tabell 1)
├── docs/                           # Referansedokumentasjon
│   ├── README.md                   # Beskrivelse av dokumenter
│   ├── SSB_korrigerte_proveresultater.pdf
│   └── UDIR_gjennomforing_resultater.pdf
├── output/                         # Generert output
│   ├── score_correction_report.pdf # Hovedrapport
│   ├── score_correction_report.md  # Rapport i Markdown-format
│   ├── verification/               # Verifiseringsresultater
│   ├── threshold_identification/   # Grenseidentifiseringsanalyse
│   │   ├── threshold_report.pdf    # Detaljert dokumentasjon
│   │   └── *.csv                   # Rådata fra analysen
│   └── plots/                      # Visualiseringer
│       ├── transformations/        # Transformasjonsplott per år/fag
│       └── discrepancy_ranges/     # Avviksintervallplott
├── archive/                        # Arkivert gammel kode og output
│   ├── README.md
│   ├── R/                          # Utgått kode
│   └── output/                     # Gammel output
└── README.md
```

## Installasjon

1. Klon eller pakk ut prosjektet til ønsket mappe
2. Sørg for at `data/npole.dta` finnes (hoveddata)
3. Åpne R eller RStudio og sett working directory til mappen:
   ```r
   setwd("/sti/til/mappen")
   ```

Nødvendige R-pakker installeres automatisk ved første kjøring:
- `data.table`
- `ggplot2`
- `here`
- `haven` (for å lese Stata-filer)

## Bruk

### Generere hovedrapporten

```r
library(here)
source(here("R", "generate_report.R"))
```

Dette laster `npole.dta`, anvender korrigeringer, og genererer:
- `output/score_correction_report.md` - Markdown-rapport
- `output/score_correction_report.pdf` - PDF-rapport (krever pandoc)
- `output/plots/transformations/` - Transformasjonsplott

### Kjøre verifiseringsanalyse

```r
library(here)
source(here("R", "verification_analysis.R"))
```

Verifiserer at beregnede mestringsnivåer matcher originaldata og analyserer effekten av korrigeringer.

### Generere avviksvisualisering

```r
library(here)
source(here("R", "discrepancy_visualization.R"))
```

Genererer plott som viser hvilke poengsummer som resulterer i nivåendring etter korrigering.

### Generere sammendragsplott

```r
library(here)
source(here("R", "shift_summary_plot.R"))
```

Genererer et facet-plott med andel elever som endret nivå, per fag og trinn over tid.

## Output

Analysen genererer følgende i `output/`-mappen:

### Hovedrapport
- `score_correction_report.pdf` - Komplett rapport med alle resultater
- `score_correction_report.md` - Samme rapport i Markdown-format

### Verifisering (`output/verification/`)
- `verification_summary.csv` - Verifisering av nivåberegninger
- `level_change_summary.csv` - Sammendrag av nivåendringer
- `transitions_detailed.csv` - Detaljerte overgangstall

### Plott (`output/plots/`)
- `shift_summary_facet.png` - Sammendragsplott for nivåendringer
- `transformations/` - 48 transformasjonsplott (ett per fag/trinn/år)
- `discrepancy_ranges/` - 6 avviksplott (ett per fag/trinn)

### Data
- `discrepancy_ranges_grade5.csv` - Avviksintervaller for 5. trinn
- `discrepancy_ranges_grade8.csv` - Avviksintervaller for 8. trinn

## Korrigeringsformel

Korrigeringen bruker SSBs formel:

```
θ_korrigert = (σ_ny / σ_gammel) × (θ_gammel - μ_gammel) + μ_ny
```

hvor:
- θ = skalapoeng
- μ = gjennomsnitt
- σ = standardavvik
- "gammel" = feilaktige parametre
- "ny" = korrekte parametre

Parametrene leses fra `data/rescaling_parameters.csv`.

## Mestringsnivågrenser

### Bakgrunn for grenseidentifisering

Martin Flatø (FHI) påpekte at grensene vi opprinnelig brukte (hentet fra Udirs dokumentasjon) ikke stemte overens med de faktiske grensene som historisk har blitt brukt i klassifiseringen. Dette motiverte en empirisk analyse for å identifisere de faktiske grensene fra registerdata.

Ifølge [Udirs rammeverk for nasjonale prøver](https://www.udir.no/eksamen-og-prover/prover/rammeverk-for-nasjonale-prover2/gjennomforing-og-resultater/) (se også `docs/UDIR_gjennomforing_resultater.pdf`):
- Grensene fastsettes etter prosentilfordeling: **25–50–25** for 5. trinn og **10–20–40–20–10** for 8. trinn
- Grensene settes i første testår og **holdes deretter konstante** over tid

Grensene nedenfor er empirisk identifisert fra første testår (2014) ved hjelp av registerdata fra SSB. Klassifiseringsregel: poengsum ≥ grense → høyere nivå. Se `output/threshold_identification/threshold_report.pdf` for detaljert dokumentasjon av grenseidentifiseringen.

### 5. trinn (3 nivåer)

Alle fag brukte samme grenser i 2014:
| Grense 1→2 | Grense 2→3 |
|:----------:|:----------:|
| 42.5 | 56.5 |

### 8. trinn (5 nivåer)

| Fag | Grense 1→2 | Grense 2→3 | Grense 3→4 | Grense 4→5 |
|---------|:----------:|:----------:|:----------:|:----------:|
| Regning | 37.0 | 45.0 | 55.0 | 63.0 |
| Lesing | 36.5 | 43.5 | 54.5 | 62.5 |
| Engelsk | 36.5 | 43.5 | 55.5 | 62.5 |

*Merk: Regning 8. trinn brukte heltallsgrenser i 2014 (37, 45, 55, 63). Fra 2015 gikk også dette faget over til X.5-grenser (36.5, 44.5, 54.5, 62.5). Tabellen viser 2014-verdiene som brukes konsekvent i analysen.*

### Metodologisk valg: Konstante grenser

Analysen bruker 2014-grensene konsekvent for alle år (2014–2021). Dette valget er gjort fordi:
1. **Udirs intensjon**: Ifølge dokumentasjonen skal grensene settes i første testår og deretter holdes konstante
2. **Sammenlignbarhet**: Konstante grenser muliggjør ren sammenligning av korreksjonseffekten over tid
3. **Verifisert**: Analysen viser >99.9% samsvar mellom beregnede nivåer og faktiske nivåtildelinger i data fra dette året

Merk at den empiriske analysen avdekket mindre grenseendringer i enkelte år (se `output/threshold_identification/threshold_report.pdf`). Disse grenseverdi-endringene er oss bekjent ikke kommunisert utad eller dokumentert tidligere. Ved å bruke konstante 2014-grenser kan våre nivåtildelinger avvike marginalt fra Udirs offisielle klassifiseringer i år der grenser faktisk ble endret.

### Analyseperiode

Analysen dekker årene **2014–2021**. Data fra 2022 og senere er ekskludert fordi skalapoengene fra dette året kun rapporteres som heltall, noe som utgjør et brudd i tidsserien og krever en annen analysemetodikk.

## Tilpasning

### Endre mestringsnivågrenser

Rediger `mastery_cutoffs` i `R/config.R`. Klassifiseringsregel: poengsum ≥ grense → høyere nivå.

```r
mastery_cutoffs <- list(
  grade5 = list(
    MATH = c(-Inf, 42.5, 56.5, Inf),  # Grenser for regning 5. trinn
    ...
  ),
  grade8 = list(
    MATH = c(-Inf, 37.0, 45.0, 55.0, 63.0, Inf),  # Grenser for regning 8. trinn
    ...
  )
)
```

### Bruke andre omskaleringsparametre

Erstatt CSV-filen i `data/` med en ny fil med samme format, eller rediger stien i `R/config.R`:

```r
rescaling_csv_path <- here("data", "din_nye_fil.csv")
```

## Feilsøking

**Problem:** Pakker installeres ikke automatisk
**Løsning:** Installer manuelt:
```r
install.packages(c("data.table", "ggplot2", "here", "haven"))
```

**Problem:** "Filen finnes ikke"
**Løsning:** Sjekk at `data/npole.dta` eksisterer.

**Problem:** PDF genereres ikke
**Løsning:** Installer pandoc: https://pandoc.org/installing.html

## Reproduserbarhet

For å reprodusere hele analysen og rapporten:

```r
library(here)

# 1. Generer avviksanalyse
source(here("R", "discrepancy_ranges.R"))

# 2. Generer avviksvisualisering
source(here("R", "discrepancy_visualization.R"))

# 3. Generer sammendragsplott
source(here("R", "shift_summary_plot.R"))

# 4. Generer hovedrapporten
source(here("R", "generate_report.R"))
```

Alternativt, kjør bare hovedskriptet som inkluderer det meste:
```r
source(here("R", "generate_report.R"))
```
