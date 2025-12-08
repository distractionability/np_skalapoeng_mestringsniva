# Korrigering av nasjonale prøveresultater

R-kode for å korrigere feilaktige skalapoeng fra nasjonale prøver (2014-2021) og analysere effekten på mestringsnivåklassifisering.

## Bakgrunn

SSB oppdaget i 2023 at skalapoengene fra nasjonale prøver hadde en feil i beregningen som førte til at spredningen (standardavviket) gradvis ble underestimert over tid. Denne koden bruker SSBs omskaleringsparametre til å korrigere poengene og viser hvor mange elever som ble feilklassifisert til feil mestringsnivå.

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
│   └── shift_summary_plot.R        # Sammendragsplott for nivåendringer
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

### 5. trinn (3 nivåer)
| Fag | Nivå 1 | Nivå 2 | Nivå 3 |
|-----|--------|--------|--------|
| Regning | ≤43 | 44-56 | ≥57 |
| Lesing | ≤42 | 43-55 | ≥56 |
| Engelsk | ≤42 | 43-57 | ≥58 |

### 8. trinn (5 nivåer)
| Fag | Nivå 1 | Nivå 2 | Nivå 3 | Nivå 4 | Nivå 5 |
|-----|--------|--------|--------|--------|--------|
| Regning | ≤37 | 38-44 | 45-54 | 55-62 | ≥63 |
| Lesing | ≤37 | 38-44 | 45-54 | 55-62 | ≥63 |
| Engelsk | ≤37 | 38-44 | 45-55 | 56-62 | ≥63 |

## Tilpasning

### Endre mestringsnivågrenser

Rediger `mastery_cutoffs` i `R/config.R`:

```r
mastery_cutoffs <- list(
  grade5 = list(
    MATH = c(-Inf, 43, 56, Inf),  # Nivågrenser for regning 5. trinn
    ...
  ),
  grade8 = list(
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
