SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APPYProcessCMEntries_sp]    	@date_applied	int,
										@debug_level	smallint = 0
AS
   DECLARE 	@trx_ctrl_num	varchar(16),
			@doc_ctrl_num	varchar(16),
			@date_doc		int,
			@trx_desc		varchar(40),
			@vendor_code	varchar(12),
			@name			varchar(40),
			@cash_acct_code	varchar(32),
			@amt_payment	float,
			@result int,	
			@org_id	varchar(30)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypcme.cpp' + ', line ' + STR( 58, 5 ) + ' -- ENTRY: '



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypcme.cpp' + ', line ' + STR( 62, 5 ) + ' -- MSG: ' + 'Create #cmdetail table'
CREATE TABLE #cmdetail
(
 trx_ctrl_num	varchar(16),
 doc_ctrl_num	varchar(16),
 date_doc		int,
 trx_desc		varchar(40),
 vendor_code	varchar(12),
 name			varchar(40),
 cash_acct_code	varchar(32),
 amt_payment	float,
 org_id		varchar(30) NULL,
 flag			smallint
)
IF @@error != 0
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypcme.cpp' + ', line ' + STR( 80, 5 ) + ' -- MSG: ' + 'Insert payment records in #cmdetail'






INSERT #cmdetail
(
 trx_ctrl_num,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 vendor_code,
 name,
 cash_acct_code,
 amt_payment,
 org_id,
 flag
)
SELECT  trx_ctrl_num,
		doc_ctrl_num,
		date_doc,
		trx_desc,
		vendor_code,
		'',
		cash_acct_code,
		amt_payment,
		org_id,
		0
FROM #appypyt_work
WHERE payment_type = 1
IF @@error != 0
	RETURN -1


UPDATE #cmdetail
SET name = apvend.vendor_name
FROM #cmdetail, apvend
WHERE #cmdetail.vendor_code = apvend.vendor_code

UPDATE #cmdetail
SET name = appayto.pay_to_name
FROM #cmdetail, #appypyt_work, appayto
WHERE #cmdetail.vendor_code = appayto.vendor_code
AND #cmdetail.trx_ctrl_num = #appypyt_work.trx_ctrl_num
AND #appypyt_work.pay_to_code = appayto.pay_to_code
AND #appypyt_work.pay_to_code != ''


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypcme.cpp' + ', line ' + STR( 130, 5 ) + ' -- MSG: ' + 'Process #cmdetail records'
WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
	  SELECT @trx_ctrl_num = trx_ctrl_num,
			 @doc_ctrl_num = doc_ctrl_num,
			 @date_doc = date_doc,
			 @trx_desc = trx_desc,
			 @vendor_code = vendor_code,
			 @name = name,
			 @cash_acct_code = cash_acct_code,
			 @amt_payment = amt_payment,
			 @org_id	= org_id
	  FROM #cmdetail
	  WHERE flag = 0

	  IF @@rowcount = 0 BREAK

	  SET ROWCOUNT 0

		EXEC @result = cminpcr_sp
						 	4000,
							2,
							4111,
							@trx_ctrl_num, 
							@doc_ctrl_num,
		   					@date_doc, 
		   					@trx_desc, 
							@vendor_code,
							@name, 
		   					@cash_acct_code, 
		   					@amt_payment, 
							0,		  
							@date_applied,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,			
							@org_id

		IF (@result != 0 )
   		RETURN  -1   
 
	  SET ROWCOUNT 1

	  UPDATE #cmdetail
	  SET flag = 1
	  WHERE flag = 0
	  
	  SET ROWCOUNT 0
   END

SET ROWCOUNT 0

DROP TABLE #cmdetail



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypcme.cpp' + ', line ' + STR( 189, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYProcessCMEntries_sp] TO [public]
GO
