SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apgooa_sp]	@currency_code varchar(8),
							@any_currency smallint,
							@process_group_num varchar(16),
							@debug_level smallint = 0,
							@from_org_onacc varchar(30),		
							@end_org_onacc varchar(30)			
AS
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 36, 5 ) + " -- ENTRY: "

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 38, 5 ) + " -- MSG: " + "Mark on-acct dependancies"




IF( (@from_org_onacc IS NULL) OR  @from_org_onacc = '' OR (LEN(RTRIM(@from_org_onacc)) = 0))
BEGIN 
SELECT DISTINCT @from_org_onacc = MIN(controlling_org_id) FROM iborgsameandrels_vw 
SELECT DISTINCT @end_org_onacc = MAX(controlling_org_id) FROM iborgsameandrels_vw 
END

UPDATE appyhdr
SET state_flag = -1,
    process_ctrl_num = @process_group_num
FROM appyhdr
WHERE ((amt_on_acct) > (0.0) + 0.0000001)
AND   void_flag = 0
AND   payment_type IN (1,3)
AND   state_flag != -1
AND   (@any_currency = 1 OR currency_code = @currency_code)
AND	  org_id BETWEEN @from_org_onacc AND @end_org_onacc				

IF @@error <> 0
   RETURN -1


CREATE TABLE #oas (trx_ctrl_num varchar(16))
IF @@error != 0
   RETURN -1
CREATE CLUSTERED INDEX oas_ind_1 ON #oas (trx_ctrl_num)
IF @@error != 0
   RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 73, 5 ) + " -- MSG: " + "---INSERT oas into #oas"
INSERT #oas (trx_ctrl_num)
SELECT trx_ctrl_num
FROM appyhdr
WHERE process_ctrl_num = @process_group_num

IF @@error != 0
   RETURN -1


CREATE TABLE #oas2 (trx_ctrl_num varchar(16))
IF @@error != 0
   RETURN -1

CREATE TABLE #oas3 (trx_ctrl_num varchar(16),
				      vendor_code varchar(12),
				      pay_to_code varchar(8),
					  doc_ctrl_num varchar(16),
					  cash_acct_code varchar(32),
					  date_doc int,
					  nat_cur_code varchar(8),
					  date_applied int,
					  rate_type_home varchar(8),
					  rate_type_oper varchar(8),
					  amt_on_acct float,
					  rate_home float,
					  rate_oper float,
					  payment_code varchar(8),
					  payment_type smallint,
					  org_id varchar(30) NULL				
					  )
IF @@error != 0
   RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 109, 5 ) + " -- MSG: " + "---Begin looping"
WHILE (1=1)
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 112, 5 ) + " -- MSG: " + "---Insert #oas2"
	SET ROWCOUNT 250

	INSERT #oas2 (trx_ctrl_num)
	SELECT trx_ctrl_num
	FROM #oas
	
	IF @@rowcount = 0 BREAK
	SET ROWCOUNT 0

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 123, 5 ) + " -- MSG: " + "---Query appyhdr to #oas3"
	INSERT #oas3 (trx_ctrl_num,
					vendor_code,
					pay_to_code,
					doc_ctrl_num,
					cash_acct_code,
					date_doc,
					nat_cur_code,
					date_applied,
					rate_type_home,
					rate_type_oper,
					amt_on_acct,
					rate_home,
					rate_oper,
					payment_code,
					payment_type,
					org_id)						
	SELECT a.trx_ctrl_num,
	       b.vendor_code,
	       b.pay_to_code,
		   b.doc_ctrl_num,
		   b.cash_acct_code,
		   b.date_doc,
		   b.currency_code,
		   b.date_applied,
		   b.rate_type_home,
		   b.rate_type_oper,
		   b.amt_on_acct,
		   b.rate_home,
		   b.rate_oper,
		   b.payment_code,
		   b.payment_type,
		   b.org_id								
	FROM #oas2 a, appyhdr b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num
	
	IF @@error != 0
   		RETURN -1


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 163, 5 ) + " -- MSG: " + "delete on-acct amounts that have unposted records"
	


	DELETE #oas3
	FROM #oas3 a, apinppyt b
	WHERE a.doc_ctrl_num = b.doc_ctrl_num
	AND a.cash_acct_code = b.cash_acct_code

	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 174, 5 ) + " -- MSG: " + "---insert info into #apgooa"
	INSERT #apgooa (trx_ctrl_num,
					 vendor_code,
					 pay_to_code,
					 doc_ctrl_num,
					 cash_acct_code,
					 date_doc,
					 nat_cur_code,
					 date_applied,
					 rate_type_home,
					 rate_type_oper,
					 amt_on_acct,
					 rate_home,
					 rate_oper,
					 payment_code,
					 payment_type,
					 org_id						
					 )
	SELECT trx_ctrl_num,
		   vendor_code,
		   pay_to_code,
		   doc_ctrl_num,
		   cash_acct_code,
		   date_doc,
		   nat_cur_code,
		   date_applied,
		   rate_type_home,
		   rate_type_oper,
		   amt_on_acct,
		   rate_home,
		   rate_oper,
		   payment_code,
		   payment_type,
		   org_id								
	FROM #oas3
	IF @@error != 0
   		RETURN -1


	SET ROWCOUNT 250
	DELETE #oas
	SET ROWCOUNT 0

	
	TRUNCATE TABLE #oas2
	TRUNCATE TABLE #oas3
END
SET ROWCOUNT 0
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 222, 5 ) + " -- MSG: " + "---End looping"


DROP TABLE #oas
DROP TABLE #oas2
DROP TABLE #oas3

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgooa.cpp" + ", line " + STR( 229, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apgooa_sp] TO [public]
GO
