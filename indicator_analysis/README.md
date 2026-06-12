# Time series processing EDA and correlation analysis

This directory contains scripts and notebooks for evaluating candidate epidemic indicators (either from the Delphi Epidata API or local CSV files) and comparing them against guiding indicators.

The analysis is split into two notebooks:
1. [indicator_evaluation.qmd](indicator_analysis/indicator_evaluation.qmd) performs a candidate-only exploratory data analysis (EDA). It evaluates one or more signals of a single candidate indicator to understand its characteristics, coverage, missingness, and versioning/revision behavior.
2. [indicator_comparison.qmd](indicator_analysis/indicator_comparison.qmd) compares a single candidate indicator against a guiding indicator (presumed ground truth) to assess its nowcasting/forecasting value via EDA overlays and correlation/lag analyses.

## Installation

To run this notebook, you need to install Quarto. You can install Quarto via:

- R package: `install.packages("quarto")`
- Download from the [Quarto website](https://quarto.org/docs/get-started/).
- Homebrew (macOS): `brew install --cask quarto`

## Running the analysis

Because these notebooks are generalized templates, they have no default indicators. You must explicitly provide all required parameters when rendering them.

### 1. Candidate Indicator Evaluation (`indicator_evaluation.qmd`)

Using the CLI:
```bash
quarto render indicator_evaluation.qmd \
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
  "indicator_evaluation.qmd",
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

### 2. Indicator Comparison (`indicator_comparison.qmd`)

Using the CLI:
```bash
quarto render indicator_comparison.qmd \
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
  "indicator_comparison.qmd",
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
Rscript indicator_evaluation_examples.R
```

---

## Notebook Parameters

### Parameters for `indicator_evaluation.qmd`

| Parameter | Description | Default |
|---|---|---|
| `source` | Data source for the candidate indicator | *None (Required)* |
| `signal` | Signal name(s) (can be a vector for multi-signal analysis) | *None (Required)* |
| `name` | Human-readable label(s) for signal(s) | *None (Required)* |
| `input_csv` | Path to local CSV containing candidate data (bypasses API) | `NULL` |
| `geo_type` | Geographic level (`state`, `county`, `hhs`, `hrr`) | *None (Required)* |
| `time_type` | Time resolution (`day`, `week`) | *None (Required)* |
| `start_day` | Start date for analysis (YYYY-MM-DD) | *None (Required)* |
| `end_day` | End date for analysis (YYYY-MM-DD) | *None (Required)* |
| `max_locations_plot` | Max locations to show in faceted plots | `60` |
| `max_archive_locs` | Max locations to fetch version history for | `60` |

### Parameters for `indicator_comparison.qmd`

| Parameter | Description | Default |
|---|---|---|
| `guiding_source` | Data source for the guiding indicator | *None (Required)* |
| `guiding_indicator` | Indicator name for the guiding indicator | *None (Required)* |
| `guiding_name` | Human-readable name for guiding indicator | *None (Required)* |
| `guiding_csv` | Path to local CSV for guiding indicator (bypasses API) | `NULL` |
| `candidate_source` | Data source for the candidate indicator | *None (Required)* |
| `candidate_indicator` | Indicator name for the candidate indicator | *None (Required)* |
| `candidate_name` | Human-readable name for candidate indicator | *None (Required)* |
| `candidate_csv` | Path to local CSV for candidate indicator (bypasses API) | `NULL` |
| `geo_type` | Geographic level (`state`, `county`, `hhs`, `hrr`) | *None (Required)* |
| `time_type` | Time resolution (`day`, `week`) | *None (Required)* |
| `start_day` | Start date for analysis (YYYY-MM-DD) | *None (Required)* |
| `end_day` | End date for analysis (YYYY-MM-DD) | *None (Required)* |
| `max_locations_plot` | Max locations to show in faceted plots | `60` |
| `max_archive_locs` | Max locations to fetch version history for | `60` |

---

## Using Local Data (CSV)

To evaluate or compare indicators using local CSV files instead of the Epidata API, set the local CSV parameters to the absolute paths of your files:
- For `indicator_evaluation.qmd`, set `input_csv`.
- For `indicator_comparison.qmd`, set `guiding_csv` and/or `candidate_csv`.

### Required CSV Structure

CSV files must include the following columns:

| Column | Description | Example |
| --- | --- | --- |
| `geo_value` | Geographic identifier | `pa`, `ny`, `06001` |
| `time_value` | Date of the observation | `2023-01-01` |
| `value` | The indicator value (numeric) | `12.4` |
| `signal` | (Optional, for multiple signals in `indicator_evaluation.qmd`) The signal identifier | `pct_ed_visits_covid` |
| `version` | (Optional) Issue/version date for revision analysis (can also be named `issue`) | `2023-01-05` |

> [!NOTE]
> If a `version` (or `issue`) column is provided, and enough revisions are available, the notebook will automatically build an `epi_archive` and enable **Revision Behavior** analysis.

### Running with Local Data Examples

```r
quarto::quarto_render(
  "indicator_evaluation.qmd",
  execute_params = list(
    input_csv = "data/candidate.csv",
    source = "Wastewater",
    signal = "wastewater_covid",
    name = "Wastewater: SARS-CoV-2 Concentration",
    geo_type = "state",
    time_type = "week",
    start_day = "2020-09-01",
    end_day = "2023-03-01"
  )
)
```

**For comparison:**
```r
quarto::quarto_render(
  "indicator_comparison.qmd",
  execute_params = list(
    guiding_csv = "data/guiding.csv",
    candidate_csv = "data/candidate.csv",
    guiding_source = "NSSP",
    guiding_indicator = "percent_visits_covid",
    guiding_name = "NSSP ED Visits: COVID-19",
    candidate_source = "Wastewater",
    candidate_indicator = "wastewater_covid",
    candidate_name = "Wastewater: SARS-CoV-2 Concentration",
    geo_type = "state",
    time_type = "week",
    start_day = "2020-09-01",
    end_day = "2023-03-01"
  )
)
```
