#!/usr/bin/env Rscript

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(quarto, here)

eval_qmd_path <- here::here("indicator_analysis", "indicator_evaluation.qmd")
comp_qmd_path <- here::here("indicator_analysis", "indicator_comparison.qmd")
rev_qmd_path <- here::here("revision_analysis", "revision_analysis.qmd")

# 1. State Comparison: HHS vs Doctor Visits
out_comp_state <- here::here("indicator_analysis", "eval_hhs_vs_doctor_visits_api_state.html")
if (!file.exists(out_comp_state)) {
  message(sprintf("Generating missing report: %s", out_comp_state))
  quarto::quarto_render(
    input = comp_qmd_path,
    output_file = "eval_hhs_vs_doctor_visits_api_state.html",
    execute_params = list(
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
  )
} else {
  message("Skipping existing report: eval_hhs_vs_doctor_visits_api_state.html")
}

# 2. State Candidate EDA: Doctor Visits
out_eval_state <- here::here("indicator_analysis", "eval_doctor_visits_smoothed_adj_cli_api_state.html")
if (!file.exists(out_eval_state)) {
  message(sprintf("Generating missing report: %s", out_eval_state))
  quarto::quarto_render(
    input = eval_qmd_path,
    output_file = "eval_doctor_visits_smoothed_adj_cli_api_state.html",
    execute_params = list(
      source = "doctor-visits",
      signal = "smoothed_adj_cli",
      name = "Doctor Visits: Smoothed Adj CLI",
      geo_type = "state",
      time_type = "day",
      start_day = "2020-09-01",
      end_day = "2023-03-01"
    )
  )
} else {
  message("Skipping existing report: eval_doctor_visits_smoothed_adj_cli_api_state.html")
}

# 3. Revision Analysis: Hospital Admissions State
out_rev_state <- here::here("revision_analysis", "revision_hospital_admissions_smoothed_covid19_from_claims_api_state.html")
if (!file.exists(out_rev_state)) {
  message(sprintf("Generating missing report: %s", out_rev_state))
  quarto::quarto_render(
    input = rev_qmd_path,
    output_file = "revision_hospital_admissions_smoothed_covid19_from_claims_api_state.html",
    execute_params = list(
      source = "hospital-admissions",
      signal = "smoothed_covid19_from_claims",
      signal_name = "Hospital Admissions: Smoothed COVID-19 from Claims",
      input_dir = "revision_analysis/data/revisions",
      geo_type = "state",
      time_type = "day",
      start_day = "2020-01-01",
      end_day = "2023-12-31"
    )
  )
} else {
  message("Skipping existing report: revision_hospital_admissions_smoothed_covid19_from_claims_api_state.html")
}

# 4. County Comparisons (Commented Out)
# out_county_jhu <- here::here("indicator_analysis", "eval_jhu_csse_vs_doctor_visits_api_county.html")
# if (!file.exists(out_county_jhu)) {
#   ...
# }
