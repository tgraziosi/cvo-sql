SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[gltrxcdf_sp] @module_id int, @debug_level smallint = 0
AS
DECLARE @jcn varchar(16),
		@sequence_id int


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gltrxcdf.cpp" + ", line " + STR( 37, 5 ) + " -- ENTRY: "





CREATE TABLE #gltrxdet_temp1( id int IDENTITY, mark_flag smallint NOT NULL, trx_state smallint NOT NULL
, journal_ctrl_num varchar(16) NOT NULL, sequence_id int NOT NULL, 
rec_company_code varchar(8) NOT NULL, company_id smallint NOT NULL, account_code varchar(32) NOT NULL,
 description varchar(40) NOT NULL, document_1 varchar(16) NOT NULL, document_2 varchar(16) NOT NULL, 
 reference_code varchar(32) NOT NULL, balance float NOT NULL, nat_balance float NOT NULL, 
 nat_cur_code varchar(8) NOT NULL, rate float NOT NULL, posted_flag smallint NOT NULL, 
 date_posted int NOT NULL, trx_type smallint NOT NULL, offset_flag smallint NOT NULL, seg1_code 
 varchar(32) NOT NULL, seg2_code varchar(32) NOT NULL, seg3_code varchar(32) NOT NULL, seg4_code 
 varchar(32) NOT NULL, seq_ref_id int NOT NULL, balance_oper float NULL, rate_oper float NULL, 
 rate_type_home varchar(8) NULL, rate_type_oper varchar(8) NULL, org_id 
 varchar(30) NULL)

CREATE CLUSTERED  INDEX  #gltrxdet_temp1_ind_0 ON #gltrxdet_temp1 ( journal_ctrl_num, sequence_id )
CREATE INDEX #gltrxdet_temp1_ind_1 ON #gltrxdet_temp1 ( journal_ctrl_num, account_code )






		INSERT  #gltrxdet_temp1 (	
			journal_ctrl_num,      
			sequence_id,    
			rec_company_code,
			company_id ,            
			account_code,   
			description,
			document_1,             
			document_2,     
			reference_code,
			balance,                
            		nat_balance,
            		balance_oper,    
			nat_cur_code,
			rate,                   
			rate_oper,
		        rate_type_home,
		        rate_type_oper,
			posted_flag,    
			date_posted,
			trx_type,               
			offset_flag,    
			seg1_code,
			seg2_code,              
			seg3_code,      
			seg4_code,
			seq_ref_id,
			trx_state,
			mark_flag,
			org_id )
			
SELECT			a.journal_ctrl_num,      
			0,    
			a.rec_company_code,
			b.company_id,            
			a.account_code,   
			"",
			"",             
			"",     
			a.reference_code,
			SUM(a.balance),                
			SUM(a.nat_balance),
			SUM(a.balance_oper),
			a.nat_cur_code,
			a.rate,                   
			a.rate_oper,
			a.rate_type_home,
			a.rate_type_oper,
			0,    
			0,
			a.trx_type,               
			0,    
			"",
			"",              
			"",      
			"",
			MIN(a.seq_ref_id),
			0,
			0,
			a.org_id 
FROM #gldist a, glcomp_vw b, glacsum c
WHERE a.rec_company_code = b.company_code
AND a.account_code = c.account_code
AND c.app_id = @module_id
GROUP BY 	a.journal_ctrl_num,a.rec_company_code,b.company_id,a.account_code,a.reference_code,
		 a.nat_cur_code, a.rate, a.rate_oper, a.rate_type_home, a.rate_type_oper,
		 a.trx_type, a.org_id





DELETE #gldist
FROM #gldist a, glacsum c
WHERE a.account_code = c.account_code
AND c.app_id = @module_id





INSERT  #gltrxdet_temp1 (	
			journal_ctrl_num,      
			sequence_id,    
			rec_company_code,
			company_id ,            
			account_code,   
			description,
			document_1,             
			document_2,     
			reference_code,
			balance,                
            nat_balance,
            balance_oper,    
			nat_cur_code,
			rate,                   
            rate_oper,
            rate_type_home,
            rate_type_oper,
			posted_flag,    
			date_posted,
			trx_type,               
			offset_flag,    
			seg1_code,
			seg2_code,              
			seg3_code,      
			seg4_code,
			seq_ref_id,
			trx_state,
			mark_flag,
			org_id )
			
SELECT		a.journal_ctrl_num,      
			0,    
			a.rec_company_code,
			b.company_id,            
			a.account_code,   
			a.description,
			a.document_1,             
			a.document_2,     
			a.reference_code,
			a.balance,                
            a.nat_balance,
            a.balance_oper,    
			a.nat_cur_code,
			a.rate,                   
            a.rate_oper,
            a.rate_type_home,
            a.rate_type_oper,
			0,    
			0,
			a.trx_type,               
			0,    
			"",
			"",              
			"",      
			"",
			a.seq_ref_id,
			0,
			0,
			a.org_id 
FROM #gldist a, glcomp_vw b
WHERE a.rec_company_code = b.company_code






TRUNCATE TABLE #gldist





UPDATE #gltrxdet_temp1	
SET seg1_code = ISNULL(SUBSTRING(a.account_code,b.start_col,b.length-b.start_col+1),"")
FROM #gltrxdet_temp1 a, glaccdef b
WHERE b.acct_level = 1

UPDATE #gltrxdet_temp1	
SET seg2_code = ISNULL(SUBSTRING(a.account_code,b.start_col,b.length-b.start_col+1),"")
FROM #gltrxdet_temp1 a, glaccdef b
WHERE b.acct_level = 2

UPDATE #gltrxdet_temp1	
SET seg3_code = ISNULL(SUBSTRING(a.account_code,b.start_col,b.length-b.start_col+1),"")
FROM #gltrxdet_temp1 a, glaccdef b
WHERE b.acct_level = 3

UPDATE #gltrxdet_temp1	
SET seg4_code = ISNULL(SUBSTRING(a.account_code,b.start_col,b.length-b.start_col+1),"")
FROM #gltrxdet_temp1 a, glaccdef b
WHERE b.acct_level = 4





create table #temp_seq_ids_byjournal (journal_ctrl_num varchar(16), min_id int, max_seq int)

INSERT INTO #temp_seq_ids_byjournal (journal_ctrl_num, min_id, max_seq)
select journal_ctrl_num, min(id) - 1 min_id, max(sequence_id) max_seq 
from #gltrxdet_temp1 
group by journal_ctrl_num 

update d 
set sequence_id = id - c.min_id + c.max_seq 
from #gltrxdet_temp1 d, #temp_seq_ids_byjournal c
where d.journal_ctrl_num = c.journal_ctrl_num 
and sequence_id = 0

INSERT INTO #gltrxdet (mark_flag, trx_state, journal_ctrl_num, sequence_id, rec_company_code, company_id, 
account_code, description, document_1, document_2, reference_code, balance, 
nat_balance, nat_cur_code, rate, posted_flag, date_posted, trx_type, offset_flag, 
seg1_code, seg2_code, seg3_code, seg4_code, seq_ref_id, balance_oper, rate_oper, 
rate_type_home, rate_type_oper, org_id)
SELECT mark_flag, trx_state, journal_ctrl_num, sequence_id, rec_company_code, company_id, 
account_code, description, document_1, document_2, reference_code, balance, 
nat_balance, nat_cur_code, rate, posted_flag, date_posted, trx_type, offset_flag, 
seg1_code, seg2_code, seg3_code, seg4_code, seq_ref_id, balance_oper, rate_oper, 
rate_type_home, rate_type_oper, org_id
FROM #gltrxdet_temp1

DROP TABLE #temp_seq_ids_byjournal
DROP TABLE #gltrxdet_temp1





SELECT journal_ctrl_num, max_seq_id = MAX(sequence_id)
INTO #temp
FROM #gltrxdet
GROUP BY journal_ctrl_num

UPDATE #gltrx
SET next_seq_id = b.max_seq_id + 1
FROM #gltrx a, #temp b
WHERE a.journal_ctrl_num = b.journal_ctrl_num

DROP TABLE #temp


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gltrxcdf.cpp" + ", line " + STR( 271, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[gltrxcdf_sp] TO [public]
GO
