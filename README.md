# Delphi RAT-SCAN

This repository contains the Delphi RAT-SCAN (Rapid Assessment Tool for Signal Correlation and iNformation), a set of parameterizable notebooks for analyzing and tracking epidemiological indicators in the Delphi data pipeline. 

## Existing Notebooks

*   [`indicator_analysis/indicator_evaluation.qmd`](indicator_analysis/indicator_evaluation.qmd). A notebook that performs candidate-only exploratory data analysis (EDA) to understand signal characteristics, coverage, missingness, and versioning/revision behavior.
*   [`indicator_analysis/indicator_correlation.qmd`](indicator_analysis/indicator_correlation.qmd). A notebook that evaluates a candidate indicator against a guiding indicator (presumed ground truth) to assess its nowcasting/forecasting value via EDA overlays and correlation/lag analyses.
*   [`revision_analysis/revision_analysis.qmd`](revision_analysis/revision_analysis.qmd). A notebook that tracks versioned time series revisions to determine how long, on average, a series continues to receive revisions after its first publication.

## Generating and Publishing Examples

The notebooks act as parameterized templates. To generate local examples and publish them as a website to GitHub Pages, the repository relies on Quarto's publishing mechanism and a pre-render hook.

Some relevant files are:

*   [`_quarto.yml`](_quarto.yml). Contains the rules for the website structure, navigation menu, and specifies the pre-render script.
*   [`scripts/pre_render.R`](scripts/pre_render.R). Automatically executes the `.qmd` notebooks with pre-defined parameters to generate static HTML examples before the website is built.
*   [`index.qmd`](index.qmd). The main page of the website. It is used to make the rendered html files visible in the website.

### Including a New Example

To add a new analysis example to the website:

1.  Add a new block of code in `scripts/pre_render.R` that calls `quarto::quarto_render()` with your desired `execute_params`. 
2. To make the rendered html visible on the website, update `_quarto.yml` and/or `index.qmd` to include a link to your newly generated HTML file.
3.  Preview or Publish:
    *   To view the changes locally, run:
        ```bash
        quarto preview
        ```
    *   To publish the updated examples directly to the `gh-pages` branch, run:
        ```bash
        quarto publish gh-pages
        ```
