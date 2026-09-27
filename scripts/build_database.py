"""XLSX ingestion only; analytical transformations live in versioned SQL."""
from pathlib import Path
import sqlite3,json,zipfile,hashlib
import pandas as pd
ROOT=Path(__file__).resolve().parents[1]
archive=ROOT/'data/raw/source.zip'
with zipfile.ZipFile(archive) as z:
 name=next(n for n in z.namelist() if n.endswith('.xlsx'))
 with z.open(name) as f:df=pd.read_excel(f,dtype={'InvoiceNo':str,'StockCode':str,'CustomerID':str})
df.columns=['invoice','stock_code','description','quantity','invoice_date','unit_price','customer_id','country']
df['invoice_date']=pd.to_datetime(df.invoice_date).dt.strftime('%Y-%m-%d %H:%M:%S')
df.insert(0,'source_row',range(2,len(df)+2))
assert df[['invoice','quantity','invoice_date','unit_price','country']].notna().all().all()
# Exact mill precision avoids binary-float accumulation and preserves source prices to 0.001 GBP.
assert ((df.unit_price*1000-(df.unit_price*1000).round()).abs()<1e-5).all()
with sqlite3.connect(ROOT/'data/retail.sqlite') as db:
 df.to_sql('raw_transactions',db,index=False,if_exists='replace')
 db.executescript((ROOT/'sql/01_model.sql').read_text())
 exports={'monthly':'SELECT * FROM monthly ORDER BY month','countries':'SELECT * FROM country_summary ORDER BY net_gbp DESC','cohorts':'SELECT * FROM cohorts ORDER BY cohort,month_index','audit':"SELECT record_class,COUNT(*) AS rows,SUM(value_mills)/1000.0 AS signed_gbp FROM classified GROUP BY record_class ORDER BY record_class"}
 results={}
 for name,sql in exports.items():
  data=pd.read_sql_query(sql,db);data.to_csv(ROOT/f'exports/{name}.csv',index=False);results[name]=json.loads(data.to_json(orient='records'))
 raw_mills=int(db.execute('SELECT SUM(value_mills) FROM classified').fetchone()[0]);classified_mills=int(db.execute('SELECT SUM(value_mills) FROM classified').fetchone()[0])
 # Independent pandas implementation audits SQL classification totals.
 duplicate=df.drop(columns='source_row').duplicated()
 sale=(~duplicate)&(df.unit_price>0)&(df.quantity>0)&~df.invoice.str.upper().str.startswith('C')
 cancel=(~duplicate)&(df.unit_price>0)&(df.quantity<0)&df.invoice.str.upper().str.startswith('C')
 values=(df.unit_price*1000).round().astype('int64')*df.quantity
 sqlnet=int(db.execute("SELECT SUM(value_mills) FROM classified WHERE record_class IN ('sale','cancellation')").fetchone()[0])
 assert int(values[sale|cancel].sum())==sqlnet
 assert int(values.sum())==raw_mills
 assert len(df)==sum(x['rows'] for x in results['audit'])
 assert abs(sum(x['net_gbp'] for x in results['monthly'])-sqlnet/1000)<.001
 assert abs(sum(x['net_gbp'] for x in results['countries'])-sqlnet/1000)<.001
 cohorts=results['cohorts'];assert all(0<=r['retention']<=1 for r in cohorts)
 assert all(r['active_customers']==r['cohort_size'] for r in cohorts if r['month_index']==0)
 meta={'source':'https://archive.ics.uci.edu/dataset/352/online-retail','citation':'Chen, D. (2015). Online Retail. UCI Machine Learning Repository. DOI: 10.24432/C5BW33','license':'CC BY 4.0','zip_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'raw_rows':len(df),'missing_customer_rows':int(df.customer_id.isna().sum()),'missing_description_rows':int(df.description.isna().sum()),'exact_duplicate_rows':int(duplicate.sum()),'raw_signed_gbp':raw_mills/1000,'min_date':df.invoice_date.min(),'max_date':df.invoice_date.max(),'checks_passed':['SQL net reconciles to independent pandas classification','Raw signed value reconciles to source','Every row classified once','Monthly totals reconcile','Country totals reconcile','Cohort rates between 0 and 1','Month-zero cohort counts reconcile']}
 results['source']=meta
 (ROOT/'reports/analysis.json').write_text(json.dumps(results,indent=2));print(json.dumps(meta,indent=2))
