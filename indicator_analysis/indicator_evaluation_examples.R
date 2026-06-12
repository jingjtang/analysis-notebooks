#!/usr/bin/env Rscript

# Load necessary libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(vroom, dplyr, readr, stringr, fs, quarto, here, rlang)

eval_qmd_path <- here::here("indicator_analysis/indicator_evaluation.qmd")
comp_qmd_path <- here::here("indicator_analysis/indicator_comparison.qmd")

# Helper to generate descriptive comparison output names
get_comp_output_name <- function(params, suffix = "") {
  name <- sprintf(
    "eval_%s_vs_%s%s.html",
    params$guiding_source,
    params$candidate_source,
    suffix
  )
  stringr::str_replace_all(name, "[[:space:]-]", "_")
}

# Helper to generate descriptive candidate evaluation output names
get_eval_output_name <- function(params, suffix = "") {
  name <- sprintf(
    "eval_%s_%s%s.html",
    params$source,
    params$signal,
    suffix
  )
  stringr::str_replace_all(name, "[[:space:]-]", "_")
}

# COVID Doctor Visits (State level)
# Candidate-only EDA
eval_params_1 <- list(
  source = "doctor-visits",
  signal = "smoothed_adj_cli",
  name = "Doctor Visits: Smoothed Adj CLI",
  geo_type = "state",
  time_type = "day",
  start_day = "2020-09-01",
  end_day = "2023-03-01"
)

quarto::quarto_render(
  input = eval_qmd_path,
  output_file = get_eval_output_name(eval_params_1, "_api_state"),
  execute_params = eval_params_1
)

# Comparison
comp_params_1 <- list(
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
  input = comp_qmd_path,
  output_file = get_comp_output_name(comp_params_1, "_api_state"),
  execute_params = comp_params_1
)

# PopHive COVID (State level)

# Candidate-only EDA
eval_params_2 <- list(
  source = "beta_pophive",
  signal = "epic_pct_covid_total",
  name = "PopHive: Epic % COVID Total",
  geo_type = "state",
  time_type = "week",
  start_day = "2020-01-01",
  end_day = "2026-03-27"
)
quarto::quarto_render(
  input = eval_qmd_path,
  output_file = get_eval_output_name(eval_params_2, "_api_state"),
  execute_params = eval_params_2
)

# Comparison
comp_params_2 <- list(
  guiding_source = "nhsn",
  guiding_indicator = "confirmed_admissions_covid_ew",
  guiding_name = "COVID Hospital Admissions (NHSN)",
  candidate_source = "beta_pophive",
  candidate_indicator = "epic_pct_covid_total",
  candidate_name = "PopHive: Epic % COVID Total",
  geo_type = "state",
  time_type = "week",
  start_day = "2020-01-01",
  end_day = "2026-03-27"
)
quarto::quarto_render(
  input = comp_qmd_path,
  output_file = get_comp_output_name(comp_params_2, "_api_state"),
  execute_params = comp_params_2
)


# PopHive Flu (State level)

# Candidate-only EDA
eval_params_3 <- list(
  source = "beta_pophive",
  signal = "epic_pct_flu_total",
  name = "PopHive: Epic % flu Total",
  geo_type = "state",
  time_type = "week",
  start_day = "2020-01-01",
  end_day = "2026-03-27"
)
quarto::quarto_render(
  input = eval_qmd_path,
  output_file = get_eval_output_name(eval_params_3, "_api_state"),
  execute_params = eval_params_3
)

# Comparison
comp_params_3 <- list(
  guiding_source = "nhsn",
  guiding_indicator = "confirmed_admissions_flu_ew",
  guiding_name = "flu Hospital Admissions (NHSN)",
  candidate_source = "beta_pophive",
  candidate_indicator = "epic_pct_flu_total",
  candidate_name = "PopHive: Epic % flu Total",
  geo_type = "state",
  time_type = "week",
  start_day = "2020-01-01",
  end_day = "2026-03-27"
)
quarto::quarto_render(
  input = comp_qmd_path,
  output_file = get_comp_output_name(comp_params_3, "_api_state"),
  execute_params = comp_params_3
)


# Local CSV NSSP vs Wastewater

# Define source URLs
url_guiding <- "https://raw.githubusercontent.com/cmu-delphi/Ingest/main/data/nssp/standard/data.csv.gz"
url_candidate <- "https://raw.githubusercontent.com/cmu-delphi/Ingest/main/data/wastewater/standard/data.csv.gz"

# Create a local data directory for processing
data_dir <- here::here("indicator_analysis/data")
if (!fs::dir_exists(data_dir)) fs::dir_create(data_dir)

# Download and process guiding data (NSSP)
df_guiding_raw <- vroom::vroom(url_guiding, show_col_types = FALSE)
df_guiding <- df_guiding_raw %>%
  rename(
    geo_value = any_of(c("geography", "state")),
    time_value = any_of(c("time", "date"))
  ) %>%
  rename(value = any_of(c("percent_visits_covid", "rate_covid", "value", "covid", "pct_covid"))) %>%
  select(geo_value, time_value, value) %>%
  filter(!is.na(value)) %>%
  filter(nchar(geo_value) == 2) %>%
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
  filter(nchar(geo_value) == 2) %>%
  mutate(
    geo_value = tolower(covidcast::fips_to_abbr(as.character(geo_value))),
    time_value = as.Date(time_value)
  ) %>%
  filter(geo_value != "us")
write_csv(df_candidate, fs::path(data_dir, "candidate.csv"))

guiding_csv_path <- fs::path_abs(fs::path(data_dir, "guiding.csv"))
candidate_csv_path <- fs::path_abs(fs::path(data_dir, "candidate.csv"))

start_day_val <- as.character(max(min(df_guiding$time_value), min(df_candidate$time_value)))
end_day_val <- as.character(min(max(df_guiding$time_value), max(df_candidate$time_value)))

# Candidate-only EDA
eval_params_4 <- list(
  source = "Wastewater",
  signal = "wastewater_covid",
  name = "Wastewater: SARS-CoV-2 Concentration",
  input_csv = as.character(candidate_csv_path),
  start_day = start_day_val,
  end_day = end_day_val,
  time_type = "week",
  geo_type = "state"
)
quarto::quarto_render(
  input = eval_qmd_path,
  output_file = get_eval_output_name(eval_params_4, "_csv_wastewater"),
  execute_params = eval_params_4
)

# Comparison
comp_params_4 <- list(
  guiding_source = "NSSP",
  guiding_indicator = "percent_visits_covid",
  guiding_name = "NSSP ED Visits: COVID-19",
  guiding_csv = as.character(guiding_csv_path),
  candidate_source = "Wastewater",
  candidate_indicator = "wastewater_covid",
  candidate_name = "Wastewater: SARS-CoV-2 Concentration",
  candidate_csv = as.character(candidate_csv_path),
  start_day = start_day_val,
  end_day = end_day_val,
  time_type = "week",
  geo_type = "state"
)
quarto::quarto_render(
  input = comp_qmd_path,
  output_file = get_comp_output_name(comp_params_4, "_csv_nssp_wastewater"),
  execute_params = comp_params_4
)


# County Level (Commented Out)
# Default API (County level) - Commented out to skip low-level geo locations during automated runs
# eval_params_5 <- list(
#   source = "doctor-visits",
#   signal = "smoothed_adj_cli",
#   name = "Doctor Visits: Smoothed Adj CLI",
#   geo_type = "county",
#   time_type = "day",
#   start_day = "2023-01-01",
#   end_day = "2023-02-01"
# )
# quarto::quarto_render(
#   input = eval_qmd_path,
#   output_file = get_eval_output_name(eval_params_5, "_api_county"),
#   execute_params = eval_params_5
# )


# NSSP vs PopHive (State level)

# Candidate-only EDA
eval_params_6 <- list(
  source = "nssp",
  signal = "smoothed_pct_ed_visits_covid",
  name = "NSSP: Smoothed % ED Visits COVID",
  geo_type = "state",
  time_type = "week",
  start_day = "2023-01-01",
  end_day = "2024-01-01"
)
quarto::quarto_render(
  input = eval_qmd_path,
  output_file = get_eval_output_name(eval_params_6, "_api_state"),
  execute_params = eval_params_6
)

# Comparison
comp_params_6 <- list(
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
  input = comp_qmd_path,
  output_file = get_comp_output_name(comp_params_6, "_api_nssp"),
  execute_params = comp_params_6
)


# NWSS: COVID-19 + Influenza wastewater concentration — state, weekly
eval_params_nwss_multi <- list(
    source = "nssp",
    signal = c("pct_ed_visits_covid", "pct_ed_visits_influenza"),
    name = c("COVID-19 % ED", "Flu % ED"),
    geo_type= "state",
    time_type = "week",
    start_day = "2022-01-01",
    end_day = "2025-12-31",
    max_locations_plot = 60,
    max_archive_locs = 60
)

quarto::quarto_render(
    input = eval_qmd_path,
    output_file = "eval_nssp_covid_flu_state.html",
    execute_params = eval_params_nwss_multi
)
