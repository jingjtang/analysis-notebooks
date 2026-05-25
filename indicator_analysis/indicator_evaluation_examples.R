#!/usr/bin/env Rscript

# Load necessary libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(vroom, dplyr, readr, stringr, fs, quarto, here, rlang)

qmd_path <- here::here("indicator_analysis/indicator_evaluation.qmd")

# Helper to generate descriptive output names
get_output_name <- function(params, suffix = "") {
  name <- sprintf(
    "eval_%s_vs_%s%s.html",
    params$guiding_source,
    params$candidate_source,
    suffix
  )
  stringr::str_replace_all(name, "[[:space:]-]", "_")
}

# Default API (State level)
params_api_state <- list(
  guiding_source = "hhs",
  guiding_indicator = "confirmed_admissions_covid_1d",
  guiding_name = "COVID Hospital Admissions (HHS)",
  candidate_source = "doctor-visits",
  candidate_indicator = "smoothed_adj_cli",
  candidate_name = "Doctor Visits: Smoothed Adj CLI",
  geo_type = "state",
  time_type = "day",
  start_day = "2020-09-01",
  end_day = "2023-03-01"
)
quarto::quarto_render(
  input = qmd_path,
  output_file = get_output_name(params_api_state, "_api_state"),
  execute_params = params_api_state
)
pophive_params <- list(
  guiding_source = "nhsn",
  guiding_indicator = "confirmed_admissions_covid_ew",
  guiding_name = "COVID Hospital Admissions (NHSN)",
  # Candidate Indicator,
  candidate_source = "beta_pophive",
  candidate_indicator = "epic_pct_covid_total",
  candidate_name = "PopHive: Epic % COVID Total",
  # Shared settings,
  geo_type = "state",
  time_type = "week",
  start_day = "2020-01-01",
  end_day = "2026-03-27"
)
quarto::quarto_render(
  input = qmd_path,
  output_file = get_output_name(pophive_params, "_api_state"),
  execute_params = pophive_params
)
pophive_params <- list(
  guiding_source = "nhsn",
  guiding_indicator = "confirmed_admissions_flu_ew",
  guiding_name = "flu Hospital Admissions (NHSN)",
  # Candidate Indicator,
  candidate_source = "beta_pophive",
  candidate_indicator = "epic_pct_flu_total",
  candidate_name = "PopHive: Epic % flu Total",
  # Shared settings,
  geo_type = "state",
  time_type = "week",
  start_day = "2020-01-01",
  end_day = "2026-03-27"
)
quarto::quarto_render(
  input = qmd_path,
  output_file = get_output_name(pophive_params, "_api_state"),
  execute_params = pophive_params
)
# md default example
# quarto::quarto_render(
#   input = qmd_path,
#   output_file = "eval_confirmed_admissions_covid_1d_vs_epic_n_covid_total_pophive_weekly.md",
#   output_format = "gfm",
#   execute_params = eval_params_1
# )

# CSV provided data (NSSP vs Wastewater at State level)

# Define source URLs
url_guiding <- "https://raw.githubusercontent.com/cmu-delphi/Ingest/main/data/nssp/standard/data.csv.gz"
url_candidate <- "https://raw.githubusercontent.com/cmu-delphi/Ingest/main/data/wastewater/standard/data.csv.gz"

# Create a local data directory for processing
data_dir <- here::here("indicator_analysis/data")
if (!fs::dir_exists(data_dir)) fs::dir_create(data_dir)

# Download and process guiding data (NSSP)
df_guiding_raw <- vroom::vroom(url_guiding, show_col_types = FALSE)

# Extract and format required columns
df_guiding <- df_guiding_raw %>%
  rename(
    geo_value = any_of(c("geography", "state")),
    time_value = any_of(c("time", "date"))
  ) %>%
  rename(value = any_of(c("percent_visits_covid", "rate_covid", "value", "covid", "pct_covid"))) %>%
  select(geo_value, time_value, value) %>%
  filter(!is.na(value)) %>%
  filter(
    nchar(geo_value) == 2
  ) %>%
  mutate(
    geo_value = tolower(covidcast::fips_to_abbr(as.character(geo_value))),
    time_value = as.Date(time_value)
  ) %>%
  filter(geo_value != "us")

write_csv(df_guiding, fs::path(data_dir, "guiding.csv"))


# Download and process candidate data (Wastewater)
df_candidate_raw <- vroom::vroom(url_candidate, show_col_types = FALSE)

df_candidate <- df_candidate_raw %>%
  rename(
    geo_value = any_of(c("geography", "state", "location")),
    time_value = any_of(c("time", "date"))
  ) %>%
  rename(value = any_of(c("wastewater_covid", "viral_concentration", "value", "concentration", "rate"))) %>%
  select(geo_value, time_value, value) %>%
  filter(!is.na(value)) %>%
  filter(
    nchar(geo_value) == 2
  ) %>%
  mutate(
    geo_value = tolower(covidcast::fips_to_abbr(as.character(geo_value))),
    time_value = as.Date(time_value)
  ) %>%
  filter(geo_value != "us")

write_csv(df_candidate, fs::path(data_dir, "candidate.csv"))

# Define absolute paths based on the new data
guiding_csv_path <- fs::path_abs(fs::path(data_dir, "guiding.csv"))
candidate_csv_path <- fs::path_abs(fs::path(data_dir, "candidate.csv"))

params_csv_nssp_wastewater <- list(
  guiding_source = "NSSP",
  guiding_indicator = "percent_visits_covid",
  guiding_name = "NSSP ED Visits: COVID-19",
  guiding_csv = as.character(guiding_csv_path),
  candidate_source = "Wastewater",
  candidate_indicator = "wastewater_covid",
  candidate_name = "Wastewater: SARS-CoV-2 Concentration",
  candidate_csv = as.character(candidate_csv_path),
  start_day = as.character(max(min(df_guiding$time_value), min(df_candidate$time_value))),
  end_day = as.character(min(max(df_guiding$time_value), max(df_candidate$time_value))),
  time_type = "week",
  geo_type = "state"
)

# Execute quarto
quarto::quarto_render(
  input = qmd_path,
  output_file = get_output_name(params_csv_nssp_wastewater, "_csv_nssp_wastewater"),
  execute_params = params_csv_nssp_wastewater
)

# Default API (County level)
params_api_county <- list(
  guiding_source = "jhu-csse",
  guiding_indicator = "confirmed_incidence_num",
  guiding_name = "JHU COVID-19 Cases",
  candidate_source = "doctor-visits",
  candidate_indicator = "smoothed_adj_cli",
  candidate_name = "Doctor Visits: Smoothed Adj CLI",
  geo_type = "county",
  time_type = "day",
  start_day = "2023-01-01",
  end_day = "2023-02-01"
)
quarto::quarto_render(
  input = qmd_path,
  output_file = get_output_name(params_api_county, "_api_county"),
  execute_params = params_api_county
)

# New cast-API source (NSSP via epidata)
params_api_nssp <- list(
  guiding_source = "beta_pophive",
  guiding_indicator = "epic_pct_covid_total",
  guiding_name = "PopHive: Epic % COVID Total",
  candidate_source = "nssp",
  candidate_indicator = "smoothed_pct_ed_visits_covid",
  candidate_name = "NSSP: Smoothed % ED Visits COVID",
  geo_type = "state",
  time_type = "week",
  start_day = "2023-01-01",
  end_day = "2024-01-01"
)
quarto::quarto_render(
  input = qmd_path,
  output_file = get_output_name(params_api_nssp, "_api_nssp"),
  execute_params = params_api_nssp
)
