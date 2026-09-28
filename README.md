# Retail Ledger

A SQL, R, and Excel analysis of recorded sales, cancellations, market concentration, and observed customer retention for a historical online retailer.

## Business questions

1. How much recorded gross sales value is offset by cancellations?
2. Which markets contribute net transaction value, and which have high cancellation-value ratios?
3. How often do identified customers purchase again after their first observed purchase month?
4. Which source-data issues change how these measures should be interpreted?

## Findings

Across the source period, under the documented cleaning assumptions:

- Gross sales value: **GBP 10,642,110.80**.
- Cancellation value: **GBP 893,979.73**, or **8.40%** of gross sales.
- Net transaction value: **GBP 9,748,131.07**.
- The UK accounts for approximately **84.0%** of net transaction value.
- **135,080 of 541,909 source rows** lack customer IDs. They remain in transaction totals but cannot be used for retention.
- **5,268 exact duplicate rows** are excluded from sales measures under an explicit assumption. The untouched raw rows remain in SQLite and the audit reconciles all classifications to the source.

Recommended investigation: validate duplicate records against the source system, review high-value cancellation invoices before attributing them to product problems, and improve customer identification coverage. Cancellation reasons and costs are absent, so this analysis does not establish causes, profit impact, or realized savings.

## Deliverables

- `Retail_Ledger.xlsx`: interactive country/date analysis using XLOOKUP, SUMIFS, COUNTIFS and validated selections; a native country PivotTable; formula-driven monthly results and native chart, sortable market table, formula-based retention heatmap with source counts, and source reconciliation. Formulas recalculate when workbook inputs change; it is not connected to a live database.
- `reports/dashboard.html`: standalone R-generated dashboard with tabs, inline charts, findings and methodology. Open it in a browser; no R installation or internet is required for viewing.
- `sql/01_model.sql`: classification, window-function duplicate handling, monthly/country views, and customer cohort CTEs.
- `sql/02_monthly_change.sql`: LAG-based month-to-month comparisons excluding the incomplete month.
- `sql/03_country_month.sql`: country-month aggregates powering the Excel selector.
- `excel/`: analysis guide and optional Power Query M staging script (not an installed connection).
- `R/dashboard.R`: R calculations, assertions, SVG charts, and HTML generation using base R.
- `exports/`: tidy SQL extracts and R monthly calculations; suitable for optional import into other BI tools. No Power BI file was created.
- `reports/analysis.json`: source checksum, quality counts and reconciliation checks.

Python is used only to ingest XLSX into SQLite, run SQL, export results, and independently audit calculations. The analysis model is SQL and the visualization code is R.

## Reproduce SQL and R

Use Python 3.12+ and either R 4.5.1 or Docker. Commands run from this folder:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdir -p data/raw
curl -L --fail https://archive.ics.uci.edu/static/public/352/online+retail.zip -o data/raw/source.zip
python scripts/build_database.py
python -m unittest discover -s tests -v
Rscript R/dashboard.R .
```

Without local R, replace the last command with:

```bash
docker run --rm -v "$PWD:/project" -w /project r-base:4.5.1 Rscript R/dashboard.R /project
```

The Docker R command was executed successfully during development. No extra R packages are required. The source archive and SQLite database are excluded from Git. The Excel workbook is a saved deliverable; rerunning this pipeline refreshes CSV/JSON and the R dashboard, not Excel. To refresh Excel for the same periods, replace its input aggregates and cohort counts with the matching exports; preserve formula columns. If periods or countries change, extend formula/chart ranges and recheck totals.

## Definitions and exclusions

Amounts are in GBP. Unit prices are preserved to source precision of GBP 0.001; integer mills avoid floating-point summation drift. Displays round to two decimals. This is a historical accounting-style summary, not audited financial statements.

A sale has positive quantity, positive price, and an invoice number not starting with C. A cancellation has negative quantity, positive price, and an invoice number starting with C. Cancellation value is shown as a positive magnitude. Net transaction value equals sales less cancellations. Other sign combinations and nonpositive prices are isolated, not silently converted to sales.

Exact duplicates match all eight original columns. Keeping only the first may remove legitimate repeated lines; the assumption is explicit and the raw data is retained. Missing descriptions do not alone exclude financial amounts. Product-level fulfillment, costs, settlement, and marketing spend are unavailable.

December 2011 ends on December 9. Full-period transaction totals include it; complete-month trends and cohort analysis exclude it. Cohorts reflect first observed purchase, not customer acquisition. Retention means at least one qualifying sale in a later month; it is not continuous subscription retention. Unobserved cohort months are blank, not zero.

## Verification

Seven source-data reconciliation checks passed, including an independent Pandas comparison of SQL net transaction value. Six SQL fixture tests cover duplicates, cancellations, missing customer IDs, retention, partial-month exclusion, and other negative adjustments.

The Excel workbook was recalculated and scanned for formula errors using its authoring engine. A source-input change correctly propagated to the net total and was restored; the original four sheets were visually inspected. Four country/date scenarios matched source aggregates, reversed dates were rejected, and original cell values/formulas and the chart were preserved. The native PivotTable cache contains 314 records and three measures and was independently parsed; Microsoft Excel refresh remains untested. See `excel/README.md` for usage and refresh limitations. Native Microsoft Excel was not available for application-level testing. R asserts that monthly gross minus cancellations equals net.

## Source and license

Chen, D. (2015). Online Retail. UCI Machine Learning Repository. https://doi.org/10.24432/C5BW33 . Dataset license: CC BY 4.0. Source: https://archive.ics.uci.edu/dataset/352/online-retail . Original project code: MIT. Derived aggregates retain this dataset attribution.

The dataset is from 2010–2011, contains wholesale activity, and is not a representation of current retail performance. Results are descriptive and should not be presented as causal evidence or current business recommendations for an identified company.
