SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROC [dbo].[CMMTProcessCMEntries_sp]    	@date_applied	int,
										@debug_level	smallint = 0
AS
   DECLARE 	@home_curr_code	varchar(8),
			@trx_ctrl_num	varchar(16),
			@trx_type		smallint,
			@doc_ctrl_num	varchar(16),
			@date_doc		int,
			@trx_desc		varchar(40),
			@account_code	varchar(32),
			@amount			float,
			@auto_rec_flag	smallint,
			@cleared_type	smallint,
			@document1		varchar(40),
			@document2		varchar(40),
			@result			int,
			@org_id varchar (30)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpcme.cpp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "


SELECT  @home_curr_code = home_currency
FROM glco 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpcme.cpp" + ", line " + STR( 67, 5 ) + " -- MSG: " + "Create #cmdetail table"
CREATE TABLE #cmdetail
(
 trx_ctrl_num	varchar(16),
 trx_type		smallint,
 doc_ctrl_num	varchar(16),
 date_doc		int,
 trx_desc		varchar(40),
 document1		varchar(40),
 document2		varchar(40),
 account_code	varchar(32),
 amount			float,
 auto_rec_flag	smallint,
 cleared_type	smallint,
 flag			smallint,
 org_id varchar(30) NULL
)
IF @@error != 0
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpcme.cpp" + ", line " + STR( 88, 5 ) + " -- MSG: " + "Insert payment records in #cmdetail"






INSERT #cmdetail
(
 trx_ctrl_num,
 trx_type,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 document1,
 document2,
 account_code,
 amount,
 auto_rec_flag,
 cleared_type,
 flag,
 org_id
)
SELECT  a.trx_ctrl_num,
		a.trx_type,
		b.doc_ctrl_num,
		b.date_document,
		a.description,
		c.trx_type_cls_desc,
		"",
		a.cash_acct_code,
		ABS(b.amount_natural) * -SIGN(-ABS(c.cleared_type - c.cash_type) + 0.5),
		b.auto_rec_flag,
		c.cleared_type,
		0,
		a.org_id
FROM #cmmanhdr_work a, #cmmandtl_work b, cmtrxcls c
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND b.trx_type_cls = c.trx_type_cls
IF @@error != 0
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpcme.cpp" + ", line " + STR( 131, 5 ) + " -- MSG: " + "Process #cmdetail records"
WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
	  SELECT @trx_ctrl_num = trx_ctrl_num,
			 @trx_type = trx_type,
			 @doc_ctrl_num = doc_ctrl_num,
			 @date_doc = date_doc,
			 @trx_desc = trx_desc,
			 @document1 = document1,
			 @document2 = document2,
			 @account_code = account_code,
			 @amount = amount,
			 @auto_rec_flag = auto_rec_flag,
			 @cleared_type = cleared_type,
			 @org_id = org_id					 
	  FROM #cmdetail
	  WHERE flag = 0

	  IF @@rowcount = 0 BREAK

	  SET ROWCOUNT 0

		EXEC @result = cminpcr_sp
						 	7000,
							2,
							@trx_type,
							@trx_ctrl_num, 
							@doc_ctrl_num, 
		   					@date_doc, 
		   					@trx_desc,
		   					@document1,
		   					@document2, 
		   					@account_code, 
		   					@amount, 
							0,		  
		   					@date_applied,
						   	NULL,
							NULL,
							NULL,
							@auto_rec_flag,
							@cleared_type,
							@org_id

		IF (@result != 0 )
   		RETURN  -1   
 
	  UPDATE #cmdetail
	  SET flag = 1
	  WHERE trx_ctrl_num = @trx_ctrl_num
	  AND account_code = @account_code
	  AND doc_ctrl_num = @doc_ctrl_num
	  AND trx_type = @trx_type
	  
   END

SET ROWCOUNT 0

DROP TABLE #cmdetail



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpcme.cpp" + ", line " + STR( 193, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMMTProcessCMEntries_sp] TO [public]
GO
