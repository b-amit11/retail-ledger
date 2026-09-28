// Change CsvPath before running. This query is not installed in the supplied workbook.
let
    CsvPath = "/replace/with/your/path/exports/country_month.csv",
    Source = Csv.Document(File.Contents(CsvPath), [Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    Typed = Table.TransformColumnTypes(Headers, {{"month", type text}, {"month_key", Int64.Type}, {"country", type text}, {"gross_gbp", type number}, {"cancellations_gbp", type number}, {"net_gbp", type number}, {"sales_invoices", Int64.Type}}, "en-GB"),
    Renamed = Table.RenameColumns(Typed, {{"month", "Month"}, {"month_key", "MonthKey"}, {"country", "Country"}, {"gross_gbp", "GrossGBP"}, {"cancellations_gbp", "CancelledGBP"}, {"net_gbp", "NetGBP"}, {"sales_invoices", "SalesInvoices"}})
in
    Renamed
