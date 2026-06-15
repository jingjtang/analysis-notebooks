#!/usr/bin/env Rscript

# Post-render script to copy landing page HTMLs and their assets
# from '_site/vignettes/' to '_site/indicator_analysis/'
# Since they are both at depth 1, relative resource paths (e.g. ../site_libs/)
# remain identical and do not need path modification. We copy instead of move
# to prevent quarto preview's watcher from throwing NotFound errors.

site_dir <- "_site"

files_to_copy <- c(
  "vignettes/eval_hhs_vs_doctor_visits_api_state.html",
  "vignettes/eval_confirmed_incidence_num_vs_doctor_visits_api_county.html"
)

for (f in files_to_copy) {
  src <- file.path(site_dir, f)
  dest <- file.path(site_dir, "indicator_analysis", basename(f))
  
  if (file.exists(src)) {
    message(sprintf("Copying compiled HTML: %s -> %s", src, dest))
    
    # Ensure destination directory exists
    dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)
    
    # Copy file
    file.copy(src, dest, overwrite = TRUE)
    
    # Also check and copy corresponding dependencies folder if it exists (e.g., HTML widgets)
    files_dir_name <- paste0(tools::file_path_sans_ext(basename(f)), "_files")
    src_files_dir <- file.path(site_dir, dirname(f), files_dir_name)
    dest_files_dir <- file.path(site_dir, "indicator_analysis", files_dir_name)
    
    if (dir.exists(src_files_dir)) {
      message(sprintf("Copying compiled HTML dependencies: %s -> %s", src_files_dir, dest_files_dir))
      if (dir.exists(dest_files_dir)) {
        unlink(dest_files_dir, recursive = TRUE)
      }
      file.copy(src_files_dir, file.path(site_dir, "indicator_analysis"), recursive = TRUE)
    }
  }
}
