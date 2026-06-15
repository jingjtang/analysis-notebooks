# Time series processing EDA and correlation analysis

This directory contains scripts and notebooks for evaluating candidate epidemic indicators (either from the Delphi Epidata API or local CSV files) and comparing them against guiding indicators.

The analysis is split into two notebooks:

1. [indicator_evaluation.qmd](indicator_evaluation.qmd) performs a candidate-only exploratory data analysis (EDA). It evaluates one or more signals of a single candidate indicator to understand its characteristics, coverage, missingness, and versioning/revision behavior.
2. [indicator_correlation.qmd](indicator_correlation.qmd) compares a single candidate indicator against a guiding indicator (presumed ground truth) to assess its nowcasting/forecasting value via EDA overlays and correlation/lag analyses.

## Installation

To run this notebook, you need to install Quarto. You can install Quarto via:

- R package: `install.packages("quarto")`
- Download from the [Quarto website](https://quarto.org/docs/get-started/).
- Homebrew (macOS): `brew install --cask quarto`

## Running the analysis

Running an analysis requires different parameters depending on the data source. For local CSV files, only the file path is required because the geographic level and time resolution are automatically inferred. For API queries, you must specify the source, signal, and geographic level. If you are querying a legacy dataset that does not support the V5 API, you must also provide the time resolution.

### 1. Candidate Indicator Evaluation (`indicator_evaluation.qmd`)

The `source`, `signal`, and `geo_type` parameters are required:

```bash
quarto render indicator_analysis/indicator_evaluation.qmd \
  -P source:nssp \
  -P signal:smoothed_pct_ed_visits_covid \
  -P geo_type:state
```

Or from R:

```r
quarto::quarto_render(
  "indicator_analysis/indicator_evaluation.qmd",
  execute_params = list(
    source = "nssp",
    signal = "smoothed_pct_ed_visits_covid",
    geo_type = "state"
  )
)
```

Full example with all options, using the CLI:

```bash
quarto render indicator_analysis/indicator_evaluation.qmd \
  -P source:doctor-visits \
  -P signal:smoothed_adj_cli \
  -P name:"Doctor Visits: Smoothed Adj CLI" \
  -P geo_type:state \
  -P time_type:day \
  -P start_day:2020-09-01 \
  -P end_day:2023-03-01
```

Or from R:

```r
quarto::quarto_render(
  "indicator_analysis/indicator_evaluation.qmd",
  execute_params = list(
    source = "doctor-visits",
    signal = "smoothed_adj_cli", # can also be a vector, e.g. c("pct_ed_visits_covid", "pct_ed_visits_influenza")
    name = "Doctor Visits: Smoothed Adj CLI", # can also be a vector, e.g. c("COVID-19 % ED", "Flu % ED")
    geo_type = "state",
    time_type = "day",
    start_day = "2020-09-01",
    end_day = "2023-03-01"
  )
)
```

### 2. Indicator Correlation (`indicator_analysis/indicator_correlation.qmd`)

The four source/indicator identifiers and `geo_type` are required:

```bash
quarto render indicator_analysis/indicator_correlation.qmd \
  -P guiding_source:nhsn \
  -P guiding_indicator:confirmed_admissions_covid_ew \
  -P candidate_source:nssp \
  -P candidate_indicator:smoothed_pct_ed_visits_covid \
  -P geo_type:state
```

Or from R:

```r
quarto::quarto_render(
  "indicator_analysis/indicator_correlation.qmd",
  execute_params = list(
    guiding_source = "nhsn",
    guiding_indicator = "confirmed_admissions_covid_ew",
    candidate_source = "nssp",
    candidate_indicator = "smoothed_pct_ed_visits_covid",
    geo_type = "state"
  )
)
```

Full example with all options, using the CLI:

```bash
quarto render indicator_analysis/indicator_correlation.qmd \
  -P guiding_source:hhs \
  -P guiding_indicator:confirmed_admissions_covid_1d \
  -P guiding_name:"COVID Hospital Admissions (HHS)" \
  -P candidate_source:google-symptoms \
  -P candidate_indicator:s02_raw_search \
  -P candidate_name:"Google Symptoms: Cough" \
  -P geo_type:state \
  -P time_type:day \
  -P start_day:2020-09-01 \
  -P end_day:2023-03-01
```

Or from R:

```r
quarto::quarto_render(
  "indicator_analysis/indicator_correlation.qmd",
  execute_params = list(
    guiding_source = "hhs",
    guiding_indicator = "confirmed_admissions_covid_1d",
    guiding_name = "COVID Hospital Admissions (HHS)",
    candidate_source = "google-symptoms",
    candidate_indicator = "s02_raw_search",
    candidate_name = "Google Symptoms: Cough",
    geo_type = "state",
    time_type = "day",
    start_day = "2020-09-01",
    end_day = "2023-03-01"
  )
)
```

### Using the Batch Script

You can use the provided example scripts in this directory rather than long `quarto` strings in the terminal.

```bash
Rscript indicator_analysis/indicator_evaluation_examples.R
```

---

## Notebook Parameters

### Parameters for `indicator_analysis/indicator_evaluation.qmd`

| Parameter | Description | Default | Requirement |
| --- | --- | --- | --- |
| `source` | Candidate indicator data source | — | Required for API; optional label override for CSV |
| `signal` | Candidate indicator signal name (or vector of signals from the same source) | — | Required for API; optional label override for CSV |
| `input_csv` | Path to local candidate CSV | `NULL` | Required for CSV |
| `name` | Display label for candidate indicator | Signal name | Optional |
| `geo_type` | Geographic level (e.g., `state`, `county`, `msa`) | `"state"` | Required for API; automatically inferred for CSV |
| `time_type` | Time resolution (`day`, `week`, `month`) | `NULL` (inferred from metadata) | Required for legacy API; automatically inferred for CSV/V5 |
| `start_day` | Start date (YYYY-MM-DD) | 2 years before `end_day` | Optional |
| `end_day` | End date (YYYY-MM-DD) | Today | Optional |
| `max_locations_plot` | Max locations in faceted plots | `60` | Optional |
| `max_archive_locs` | Max locations for version history | `60` | Optional |
| `min_archive_days` | Min days of history for revision analysis | `60` | Optional |

### Parameters for `indicator_analysis/indicator_correlation.qmd`

| Parameter | Description | Default | Requirement |
| --- | --- | --- | --- |
| `guiding_source` | Guiding indicator data source | — | Required for API; optional for CSV |
| `guiding_indicator` | Guiding indicator signal name | — | Required for API; optional for CSV |
| `guiding_csv` | Path to local guiding CSV | `NULL` | Required for CSV |
| `guiding_name` | Display label for guiding indicator | `guiding_indicator` value | Optional |
| `candidate_source` | Candidate indicator data source | — | Required for API; optional for CSV |
| `candidate_indicator` | Candidate indicator signal name | — | Required for API; optional for CSV |
| `candidate_csv` | Path to local candidate CSV | `NULL` | Required for CSV |
| `candidate_name` | Display label for candidate indicator | `candidate_indicator` value | Optional |
| `geo_type` | Geographic level (e.g., `state`, `county`, `msa`) | `"state"` | Required for API; automatically inferred for CSV |
| `time_type` | Time resolution (`day`, `week`, `month`) | `NULL` (inferred from metadata) | Required for legacy API; automatically inferred for CSV/V5 |
| `start_day` | Start date (YYYY-MM-DD) | 2 years before `end_day` | Optional |
| `end_day` | End date (YYYY-MM-DD) | Today | Optional |
| `max_locations_plot` | Max locations in faceted plots | `60` | Optional |
| `max_archive_locs` | Max locations for version history | `60` | Optional |
| `min_archive_days` | Min days of history for revision analysis | `60` | Optional |

---

## Using Local Data (CSV)

To run the analysis with local CSV files instead of querying the Epidata API, specify the path to your CSV files. The notebooks automatically infer the geographic level and time resolution directly from the data.

- For `indicator_analysis/indicator_evaluation.qmd`, set the `input_csv` parameter.
- For `indicator_analysis/indicator_correlation.qmd`, set the `guiding_csv` and/or `candidate_csv` parameters.

Other API parameters (such as `source`, `signal`, and display names) serve as optional label overrides to customize titles and legends in the plots. If omitted, they default to the CSV filename and column names.

### Required CSV Structure

CSV files must include the following columns:

| Column | Description | Example |
| --- | --- | --- |
| `geo_value` | Geographic identifier | `pa`, `ny`, `06001` |
| `time_value` | Date of the observation | `2023-01-01` |
| `value` | The indicator value (numeric) | `12.4` |
| `signal` | (Optional, for multiple signals) The signal identifier | `pct_ed_visits_covid` |
| `version` | (Optional) Issue/version date for revision analysis (can also be named `issue`) | `2023-01-05` |

> [!NOTE]
> Including a `version` (or `issue`) column automatically enables the **Revision Behavior** analysis.

### Running with Local Data Examples

Minimal evaluation run (labels inferred from CSV name):

```r
quarto::quarto_render(
  "indicator_analysis/indicator_evaluation.qmd",
  execute_params = list(
    input_csv = "data/candidate.csv"
  )
)
```

Evaluation run with optional metadata labels:

```r
quarto::quarto_render(
  "indicator_analysis/indicator_evaluation.qmd",
  execute_params = list(
    input_csv = "indicator_analysis/data/candidate.csv",
    source = "Wastewater",
    signal = "wastewater_covid"
  )
)
```

Minimal comparison run:

```r
quarto::quarto_render(
  "indicator_analysis/indicator_correlation.qmd",
  execute_params = list(
    guiding_csv = "data/guiding.csv",
    candidate_csv = "data/candidate.csv"
  )
)
```
