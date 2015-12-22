SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO







CREATE PROC [dbo].[APPAProcessCMEntries_sp]    	@date_applied	int,
										@debug_level	smallint = 0
AS
   DECLARE 	@trx_ctrl_num		varchar(16),
			@doc_ctrl_num		varchar(16),
			@date_doc			int,
			@trx_desc			varchar(40),
			@vendor_code		varchar(12),
			@name				varchar(40),
			@cash_acct_code		varchar(32),
			@amt_payment		float,
			@result				int,
			@trx_type			smallint,
			@apply_to_trx_num	varchar(16),
			@apply_to_trx_type	smallint,
			@apply_to_doc_num	varchar(16),
			@void_flag			smallint,
			@org_id			varchar(30)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapcme.cpp' + ', line ' + STR( 68, 5 ) + ' -- ENTRY: '



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapcme.cpp' + ', line ' + STR( 72, 5 ) + ' -- MSG: ' + 'Create #cmdetail table'
CREATE TABLE #cmdetail
(
 trx_type			smallint,
 trx_ctrl_num		varchar(16),
 doc_ctrl_num		varchar(16),
 date_doc			int,
 trx_desc			varchar(40),
 vendor_code		varchar(12),
 name				varchar(40),
 cash_acct_code		varchar(32),
 amt_payment		float,
 void_flag			smallint,
 apply_to_trx_num	varchar(16) NULL,
 apply_to_trx_type	smallint NULL,
 apply_to_doc_num	varchar(16) NULL,
 org_id			varchar(30) NULL,
 flag				smallint
)
IF @@error != 0
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapcme.cpp' + ', line ' + STR( 95, 5 ) + ' -- MSG: ' + 'Insert payment records in #cmdetail'






INSERT #cmdetail
(
 trx_type,
 trx_ctrl_num,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 vendor_code,
 name,
 cash_acct_code,
 amt_payment,
 void_flag,
 apply_to_trx_num,
 apply_to_trx_type,
 apply_to_doc_num,
 org_id,
 flag
)
SELECT  4112,
		a.trx_ctrl_num,
		a.doc_ctrl_num,
		a.date_doc,
	   	a.trx_desc,
		a.vendor_code,
		'',
		a.cash_acct_code,
		-a.amt_payment,
		1,
		b.trx_ctrl_num,
		b.trx_type,
		b.doc_ctrl_num,
		a.org_id,
		0
FROM #appapyt_work a, #appatrxp_work b
WHERE a.payment_type = 1
AND a.void_type != 4
AND a.doc_ctrl_num = b.doc_ctrl_num
AND a.cash_acct_code = b.cash_acct_code
IF @@error != 0
	RETURN -1



INSERT #cmdetail
(
 trx_type,
 trx_ctrl_num,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 vendor_code,
 name,
 cash_acct_code,
 amt_payment,
 void_flag,
 org_id,
 flag
)
SELECT  4121,
		a.trx_ctrl_num,
		a.doc_ctrl_num,
		a.date_doc,
	   	a.trx_desc,
		a.vendor_code,
		'',
		a.cash_acct_code,
		b.amt_serv_chrg,
		0,
		a.org_id,
		0
FROM #appapyt_work a, apcash b
WHERE payment_type = 1
AND void_type IN (1,2)
AND a.cash_acct_code = b.cash_acct_code


UPDATE #cmdetail
SET name = apvend.vendor_name
FROM #cmdetail, apvend
WHERE #cmdetail.vendor_code = apvend.vendor_code

UPDATE #cmdetail
SET name = appayto.pay_to_name
FROM #cmdetail, #appapyt_work, appayto
WHERE #cmdetail.vendor_code = appayto.vendor_code
AND #cmdetail.trx_ctrl_num = #appapyt_work.trx_ctrl_num
AND #appapyt_work.pay_to_code = appayto.pay_to_code
AND #appapyt_work.pay_to_code != ''


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapcme.cpp' + ', line ' + STR( 192, 5 ) + ' -- MSG: ' + 'Process #cmdetail records'
WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
	  SELECT @trx_type = trx_type,
	  		 @trx_ctrl_num = trx_ctrl_num,
			 @doc_ctrl_num = doc_ctrl_num,
			 @date_doc = date_doc,
			 @trx_desc = trx_desc,
			 @vendor_code = vendor_code,
			 @name = name,
			 @cash_acct_code = cash_acct_code,
			 @amt_payment = amt_payment,
			 @void_flag = void_flag,
			 @apply_to_trx_num = apply_to_trx_num,
			 @apply_to_trx_type = apply_to_trx_type,
			 @apply_to_doc_num = apply_to_doc_num,
			 @org_id	 = org_id 
	  FROM #cmdetail
	  WHERE flag = 0

	  IF @@rowcount = 0 BREAK

	  SET ROWCOUNT 0

		EXEC @result = cminpcr_sp
						 	4000,
							2,
							@trx_type,
							@trx_ctrl_num, 
							@doc_ctrl_num, 
		   					@date_doc, 
		   					@trx_desc, 
							@vendor_code,
							@name,
		   					@cash_acct_code, 
		   					@amt_payment, 
							@void_flag,		  
		   					@date_applied,
							@apply_to_trx_num,
							@apply_to_trx_type,
							@apply_to_doc_num,
							NULL,
							NULL, -- Rev 1.0
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



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapcme.cpp' + ', line ' + STR( 255, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAProcessCMEntries_sp] TO [public]
GO
