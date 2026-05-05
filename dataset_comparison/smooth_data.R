#!/usr/bin/env Rscript
# smooth_data.R
# Applies the left Gaussian linear filter to a dataset

if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, cli, arrow, fs, glue)

# Left Gaussian linear smoother
left_gauss_linear_r <- function(signal, h = 100) {
  n <- length(signal)
  if (n == 0) return(numeric(0))
  out <- rep(NA_real_, n)
  
  # Window size: where weight drops below 1e-14 (approx 57 days for h=100)
  w_size <- ceiling(sqrt(32.2 * h))
  
  for (idx in seq_len(n)) {
    if (idx < 2) next # Need at least 2 points to fit a line
    
    start <- max(1, idx - w_size)
    rel_idx <- (start:idx) - idx  
    wts <- exp(-(rel_idx^2) / h)
    yy  <- signal[start:idx]
    
    # Analytical 2x2 Local Linear Regression
    # We want beta_0 where y ~ beta_0 + beta_1 * rel_idx
    sw   <- sum(wts)
    swx  <- sum(wts * rel_idx)
    swx2 <- sum(wts * rel_idx^2)
    swy  <- sum(wts * yy)
    swxy <- sum(wts * rel_idx * yy)
    
    det <- sw * swx2 - swx * swx
    if (abs(det) > 1e-12) {
      # beta_0 = (sum(w*x^2) * sum(w*y) - sum(w*x) * sum(w*x*y)) / det
      out[idx] <- (swx2 * swy - swx * swxy) / det
    }
  }
  out
}

# Helper to transform datasets with Gaussian smoother
add_smoothed_column <- function(df, signal_col = "value", new_col = "value_smoothed", h = 100) {
  if (new_col %in% names(df)) {
    cli::cli_abort("Column '{new_col}' already exists in the dataset.")
  }

  # sort by version and time_value
  df <- df |> dplyr::arrange(version, time_value)
  versions <- sort(unique(df$version))
  
  # map all time_values to a fixed index for the snapshot vector
  all_times <- sort(unique(df$time_value))
  time_map <- setNames(seq_along(all_times), as.character(all_times))
  
  # current_snapshot tracks the latest known value for every date
  current_snapshot <- rep(NA_real_, length(all_times))
  df[[new_col]] <- NA_real_
  
  max_idx_so_far <- 0
  
  cli::cli_progress_bar("Smoothing versions", total = length(versions))

  # Iterate through versions
  for (v in versions) {
    v_idx <- which(df$version == v)
    if (length(v_idx) == 0) {
      cli::cli_progress_update()
      next
    }
    v_data <- df[v_idx, ]
    
    # Update our snapshot with values from this version
    indices <- time_map[as.character(v_data$time_value)]
    current_snapshot[indices] <- v_data[[signal_col]]
    
    # temporal horizon is the furthest date seen
    max_idx_so_far <- max(max_idx_so_far, max(indices))
    
    # Apply scaled/clipped smoothing to the current snapshot
    sig <- current_snapshot[1:max_idx_so_far]
    sig[is.na(sig)] <- 0 # Gap fill 
    
    rng <- range(sig, na.rm = TRUE)
    min_v <- rng[1]; max_v <- rng[2]; diff_v <- max_v - min_v
    
    if (!is.na(diff_v) && diff_v > 1e-12) {
      sig_scaled <- (sig - min_v) / diff_v
      sm_scaled <- left_gauss_linear_r(sig_scaled, h = h)
      sm_sig <- (sm_scaled * diff_v) + min_v
    } else {
      sm_sig <- left_gauss_linear_r(sig, h = h)
    }
    
    # Store results
    df[[new_col]][v_idx] <- pmax(sm_sig[indices], 0)
    cli::cli_progress_update() 
  }

  cli::cli_progress_done()
  df
}

# Script execution

if (sys.nframe() == 0 && interactive() == FALSE) {
  # Setup
  indicator <- "dv"
  geo_type  <- "hrr"
  
  data_path <- fs::path("dataset_comparison", "data", geo_type, "new", 
                        glue("new_{indicator}_{geo_type}.parquet"))
  
  out_dir <- fs::path(fs::path_dir(data_path), 
                      glue("new_{indicator}_{geo_type}_smoothed_dataset"))
  
  if (fs::file_exists(data_path)) {
    cli::cli_h1("Archival Smoothing")
    cli::cli_alert_info("Source: {data_path}")
    cli::cli_alert_info("Output: {out_dir}")
    
    # Open dataset
    ds <- arrow::open_dataset(data_path)
    
    # Get geographies
    geos <- ds |> dplyr::distinct(geo_value) |> dplyr::collect() |> dplyr::pull(geo_value)
    
    cli::cli_alert_info("Found {length(geos)} geographies to process.")
    
    if (!fs::dir_exists(out_dir)) fs::dir_create(out_dir)
    
    processed_rows <- 0
    total_rows <- ds |> dplyr::count() |> dplyr::collect() |> dplyr::pull(n)
    cli::cli_inform("Total rows to process: {scales::comma(total_rows)}")

    for (g in geos) {
      # Check if this geography has already been processed
      partition_path <- fs::path(out_dir, glue("geo_value={g}"))
      
      if (fs::dir_exists(partition_path)) {
        # Count rows in existing partition to keep progress %
        n_existing <- arrow::open_dataset(partition_path) |> dplyr::count() |> dplyr::collect() |> dplyr::pull(n)
        processed_rows <- processed_rows + n_existing
        pct <- round(100 * processed_rows / total_rows, 1)
        
        cli::cli_alert_info("Skipping {g} (already processed). Total: {scales::comma(processed_rows)} ({pct}%)")
        next
      }

      cli::cli_h2("Processing {g}")
      
      # Load only the history for this geography
      geo_chunk <- ds |> dplyr::filter(geo_value == g) |> dplyr::collect()
      n_chunk <- nrow(geo_chunk)
      
      # Apply smoothing
      geo_smoothed <- add_smoothed_column(geo_chunk, signal_col = "value", new_col = "value_smoothed")
      
      # Round values to 5 decimals to maximize compression 
      geo_smoothed$value <- round(geo_smoothed$value, 5)
      geo_smoothed$value_smoothed <- round(geo_smoothed$value_smoothed, 5)
      
      # Save location
      arrow::write_dataset(geo_smoothed, out_dir, format = "parquet", 
                           partitioning = "geo_value", compression = "zstd", compression_level = 5)
      
      # Update
      processed_rows <- processed_rows + n_chunk
      pct <- round(100 * processed_rows / total_rows, 1)
      cli::cli_alert_success("Finished {g} ({scales::comma(n_chunk)} rows). Total: {scales::comma(processed_rows)} ({pct}%)")

      # Garbage collection
      rm(geo_chunk, geo_smoothed)
      gc(verbose = FALSE)
    }
    
    cli::cli_h1("Processing Complete")

    if (processed_rows == total_rows) {
      final_path <- fs::path(fs::path_dir(data_path), 
                             glue("new_{indicator}_{geo_type}_smoothed.parquet"))
      
      cli::cli_h2("Finalizing Dataset")
      cli::cli_alert_info("Removing old monolithic file: {data_path}")
      fs::file_delete(data_path)
      
      cli::cli_alert_info("Promoting partitioned dataset to: {final_path}")
      if (fs::dir_exists(final_path)) fs::dir_delete(final_path)
      fs::file_move(out_dir, final_path)
      
      cli::cli_alert_success("Success! Definitive smoothed dataset is ready at {final_path}")
    } else {
      cli::cli_alert_warning("Processing interrupted. Progress saved in {out_dir}. Run again to resume.")
    }
  } else {
    cli::cli_alert_danger("File not found: {data_path}")
  }
}
