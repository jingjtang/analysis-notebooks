#' Data Extraction for Dataset Comparison
#'
#' old signals: fetched monthly via pub_covidcast and stored as individual
#'   parquet files in data/old/monthly/{signal_name}/
#' new signals: fetched in one shot from cast-API and stored as a single
#'   parquet in data/new/
#'
#' Re-running is safe: monthly files that already exist are skipped.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(epidatr, tidyverse, arrow, fs, lubridate, glue, cli)

# Change geo_type to download a different geographic level.
# multiple geo levels can coexist.
pars <- list(
    geo_type  = "state",
    start_day = "2020-01-01",
    end_day   = as.character(Sys.Date()),
    cast_token = Sys.getenv("DELPHI_EPIDATA_KEY"),

    # Old signals
    old_hosp_source      = "hospital-admissions",
    old_hosp_signal      = "smoothed_covid19_from_claims",
    old_dv_source        = "doctor-visits",
    old_dv_signal        = "smoothed_cli",

    # New signals
    new_hosp_source = "claims_data_inpatient",
    new_hosp_signal = "claims_inpatient_adm_pct_claims_covid",
    new_dv_source   = "claims_data_outpatient",
    new_dv_signal   = "claims_outpatient_ov_pct_claims_covid"
)

# Helper to fetch new signals
fetch_new_signal_full <- function(source, signal, name, dir, token) {
    cli_h2("Fetching NEW signal: {name}")
    dest_parquet <- path(dir, paste0(name, ".parquet"))

    if (file_exists(dest_parquet)) {
        cli_alert_info("{name}.parquet already exists – skipping.")
        return(invisible(NULL))
    }

    dest_csv <- path(dir, paste0(name, "_temp.csv"))
    vq <- glue("<{as.character(Sys.Date() + 1)}")

    url <- glue(
        "https://delphi.cmu.edu/epidata/v5/", # Prod URL
        "archive/",
        "?source={source}&signal={signal}&geo_type={pars$geo_type}",
        "&version_query={URLencode(vq, reserved = TRUE)}&use_pagination=false",
        # "&columns=signal%2Cfill_method%2Cgeo_value%2Ctime_value",
        # "%2Creport_ts_nominal_start%2Cvalue", 
        "&format=csv&header=true"
    )

    cli_inform(c(">" = "curl {name}..."))
    cmd <- glue(
        "curl -s -X 'GET' '{url}'",
        " -H 'accept: text/csv' -H 'token: {token}'",
        " -o '{dest_csv}' -w '%{{http_code}}'"
    )

    http_code <- system(cmd, intern = TRUE)

    if (http_code == "200" && file_exists(dest_csv) && file_info(dest_csv)$size > 1000) {
        cli_alert_success("Download complete. Converting to Parquet...")
        # This maps the CSV without loading it into memory, and write_parquet 
        # will stream the data into the output file.
        ds <- arrow::open_dataset(dest_csv, format = "csv")
        arrow::write_parquet(ds, dest_parquet)
        
        file_delete(dest_csv)
        cli_alert_success("Saved {dest_parquet}")
    } else {
        cli_alert_danger("Failed {name}. HTTP: {http_code}")
        if (file_exists(dest_csv)) file_delete(dest_csv)
    }
}

# Helper to fetch old etl signals
fetch_old_signal_monthly <- function(source, signal, name, monthly_dir) {
    cli_h2("Fetching OLD signal: {name}")
    dir_create(monthly_dir)

    month_starts <- seq(as.Date(pars$start_day), as.Date(pars$end_day), by = "month")
    month_ends   <- ceiling_date(month_starts, "month") - days(1)
    month_ends[length(month_ends)] <- min(
        month_ends[length(month_ends)], as.Date(pars$end_day)
    )

    for (i in seq_along(month_starts)) {
        s <- month_starts[i]
        e <- month_ends[i]

        file_name <- glue("{name}_{format(s, '%Y_%m')}.parquet")
        file_path <- path(monthly_dir, file_name)

        if (file_exists(file_path)) {
            cli_inform(c("-" = "Skipping {format(s, '%Y-%m')} (exists)"))
            next
        }

        cli_inform(c(">" = "Downloading {s} to {e}..."))

        tryCatch({
            df_chunk <- pub_covidcast(
                source     = source,
                signal     = signal,
                geo_type   = pars$geo_type,
                time_type  = "day",
                time_values = epirange(s, e),
                issues     = "*"
            )
            if (nrow(df_chunk) > 0) {
                df_chunk <- df_chunk |> distinct() |> mutate(time_value = as.Date(time_value))
                write_parquet(df_chunk, file_path)
                cli_alert_success("Saved {file_name} ({nrow(df_chunk)} rows)")
            } else {
                cli_warn("No data for {s} to {e}")
            }
        }, error = function(err) {
            cli_alert_danger("Failed {s}–{e}: {err$message}")
        })
    }
}

# setup directories
geo <- pars$geo_type

new_dir <- here::here("dataset_comparison", "data", geo, "new")
old_dir <- here::here("dataset_comparison", "data", geo, "old")
dir_create(new_dir)
dir_create(old_dir)

# Nwe signals 
fetch_new_signal_full(pars$new_dv_source,   pars$new_dv_signal,   glue("new_dv_{geo}"),   new_dir, pars$cast_token)
fetch_new_signal_full(pars$new_hosp_source, pars$new_hosp_signal, glue("new_hosp_{geo}"), new_dir, pars$cast_token)

# Old signals 
fetch_old_signal_monthly(
    pars$old_dv_source, pars$old_dv_signal, glue("old_dv"),
    path(old_dir, "monthly", glue("old_dv"))
)
fetch_old_signal_monthly(
    pars$old_hosp_source, pars$old_hosp_signal, glue("old_hosp"),
    path(old_dir, "monthly", glue("old_hosp"))
)

cli_h1("Extraction complete.")
