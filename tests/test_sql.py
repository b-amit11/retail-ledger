import sqlite3,unittest
from pathlib import Path
class SQLTests(unittest.TestCase):
 def setUp(self):
  self.db=sqlite3.connect(':memory:')
  self.db.execute('CREATE TABLE raw_transactions(source_row INTEGER,invoice TEXT,stock_code TEXT,description TEXT,quantity INTEGER,invoice_date TEXT,unit_price REAL,customer_id TEXT,country TEXT)')
  rows=[(1,'1','A','Item',2,'2011-01-01',10,'100','UK'),(2,'1','A','Item',2,'2011-01-01',10,'100','UK'),(3,'C1','A','Item',-1,'2011-01-02',10,'100','UK'),(4,'2','A','Item',1,'2011-02-01',10,'100','UK'),(5,'3','A','Item',1,'2011-02-01',10,None,'UK'),(6,'4','A','Item',1,'2011-02-02',0,'100','UK'),(7,'5','A','Item',-1,'2011-02-03',10,'100','UK'),(8,'6','A','Item',1,'2011-12-01',10,'100','UK')]
  self.db.executemany('INSERT INTO raw_transactions VALUES(?,?,?,?,?,?,?,?,?)',rows)
  self.db.executescript((Path(__file__).resolve().parents[1]/'sql/01_model.sql').read_text())
 def tearDown(self):self.db.close()
 def test_duplicate_classification(self):self.assertEqual(self.db.execute("SELECT COUNT(*) FROM classified WHERE record_class='duplicate'").fetchone()[0],1)
 def test_net_reconciles(self):self.assertEqual(self.db.execute('SELECT SUM(net_gbp) FROM monthly').fetchone()[0],40)
 def test_missing_ids_retained_in_sales(self):self.assertEqual(self.db.execute("SELECT unidentified_net_gbp FROM monthly WHERE month='2011-02'").fetchone()[0],10)
 def test_retention_excludes_partial(self):self.assertEqual(self.db.execute('SELECT MAX(month) FROM cohorts').fetchone()[0],'2011-02')
 def test_cohort_distinct_buyers(self):self.assertEqual(self.db.execute("SELECT active_customers FROM cohorts WHERE month_index=1").fetchone()[0],1)
 def test_other_negative_adjustment(self):self.assertEqual(self.db.execute("SELECT record_class FROM classified WHERE source_row=7").fetchone()[0],'other_adjustment')
if __name__=='__main__':unittest.main()
