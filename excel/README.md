# Excel analysis guide

Open `Retail_Ledger.xlsx` in Excel with XLOOKUP support. Start on **Explore** and change the amber country, start-month, and end-month cells. Month keys use YYYYMM. For Germany, January–June 2011, net transaction value is **GBP 90,132.18**, with 171 sales invoices and six observed country-months.

- **SUMIFS** filters gross sales, cancellations, and invoice counts by country and inclusive month range.
- **COUNTIFS** counts observed country-month rows, not transactions or customers.
- **XLOOKUP** retrieves the country's full-period net value from Markets to compare selected-period contribution.
- **IF/COUNTIF/AND** detect invalid selections and reversed dates. Missing source rows produce zero totals; they do not establish that a market had no activity outside this dataset.
- **Country Pivot** is a native PivotTable with 314 cached source records, country rows, and three summed measures. Its source is the `CountryMonthData` table. The pivot package and cache were independently parsed, but opening/refreshing in Microsoft Excel was not tested. Right-click inside the pivot and refresh after changing source values; check totals against Markets.
- **Monthly**, **Markets**, **Cohorts**, and **Audit** retain the original analysis, chart, retention formulas, and reconciliation.

XLOOKUP is used instead of redundant VLOOKUP. There is no claim that every Excel feature is included. The workbook supports descriptive investigation, not predictions or causal conclusions.

## Optional Power Query staging

`country_month.pq` is a supplied M query, **not an active workbook connection** and not application-tested. In an Excel version supporting Power Query, create a blank query, open its Advanced Editor, paste the script, and replace `CsvPath` with your absolute CSV path. Load the result to a new worksheet as a staging table. Verify 314 rows for the supplied export and reconcile the three monetary totals before using it.

To update the analysis for the same countries and months, copy the staging table's data values into CountryMonth's existing table, preserving the seven columns and headers. Refresh the PivotTable. Explore currently uses source rows 6–319; extend its formula ranges if the dataset grows. Markets and other sheets are separate saved aggregates and must also be updated from their matching exports. This is deliberately documented as a manual integration, not a one-click end-to-end refresh.

[Microsoft Csv.Document reference](https://learn.microsoft.com/en-us/powerquery-m/csv-document).
