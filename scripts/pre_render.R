#!/usr/bin/env Rscript

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(quarto, here)

eval_qmd_path <- here::here("indicator_analysis", "indicator_evaluation.qmd")
comp_qmd_path <- here::here("indicator_analysis", "indicator_correlation.qmd")
rev_qmd_path <- here::here("revision_analysis", "revision_analysis.qmd")

# 1. State Comparison: HHS vs Doctor Visits
out_comp_state <- here::here("indicator_analysis", "comp_hhs_vs_doctor_visits_api_state.html")
if (!file.exists(out_comp_state)) {
  message(sprintf("Generating missing report: %s", out_comp_state))
  quarto::quarto_render(
    input = comp_qmd_path,
    output_file = "comp_hhs_vs_doctor_visits_api_state.html",
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
  message("Skipping existing report: comp_hhs_vs_doctor_visits_api_state.html")
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

# 3. County Comparison: JHU CSSE vs Doctor Visits
out_county_comp <- here::here("indicator_analysis", "eval_jhu_csse_vs_doctor_visits_api_county.html")
if (!file.exists(out_county_comp)) {
  message(sprintf("Generating missing report: %s", out_county_comp))
  quarto::quarto_render(
    input = comp_qmd_path,
    output_file = "eval_jhu_csse_vs_doctor_visits_api_county.html",
    execute_params = list(
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
  )
} else {
  message("Skipping existing report: eval_jhu_csse_vs_doctor_visits_api_county.html")
}

# 4. County Candidate EDA: Doctor Visits
out_county_eval <- here::here("indicator_analysis", "eval_doctor_visits_smoothed_adj_cli_api_county.html")
if (!file.exists(out_county_eval)) {
  message(sprintf("Generating missing report: %s", out_county_eval))
  quarto::quarto_render(
    input = eval_qmd_path,
    output_file = "eval_doctor_visits_smoothed_adj_cli_api_county.html",
    execute_params = list(
      source = "doctor-visits",
      signal = "smoothed_adj_cli",
      name = "Doctor Visits: Smoothed Adj CLI",
      geo_type = "county",
      time_type = "day",
      start_day = "2023-01-01",
      end_day = "2023-02-01"
    )
  )
} else {
  message("Skipping existing report: eval_doctor_visits_smoothed_adj_cli_api_county.html")
}

# 5. Revision Analysis: Hospital Admissions State
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
