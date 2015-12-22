SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROC [dbo].[CMBTProcessCMEntries_sp]    	@date_applied	int,
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
			@result			int,
			@id 			numeric,
			@org_id varchar(30)
			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtpcme.cpp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "


SELECT @id = 1
SELECT  @home_curr_code = home_currency
FROM glco 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtpcme.cpp" + ", line " + STR( 68, 5 ) + " -- MSG: " + "Create #cmdetail table"
CREATE TABLE #cmdetail
(
 trx_ctrl_num	varchar(16),
 trx_type		smallint,
 doc_ctrl_num	varchar(16),
 date_doc		int,
 trx_desc		varchar(40),
 document1		varchar(40),
 account_code	varchar(32),
 amount			float,
 auto_rec_flag	smallint,
 cleared_type	smallint,
 flag			smallint,
 id 			numeric identity,
 org_id varchar (30) NULL
)
IF @@error != 0
	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtpcme.cpp" + ", line " + STR( 89, 5 ) + " -- MSG: " + "Insert payment records in #cmdetail"






INSERT #cmdetail
(
 trx_ctrl_num,
 trx_type,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 document1,
 account_code,
 amount,
 auto_rec_flag,
 cleared_type,
 flag,
 org_id
)
SELECT  a.trx_ctrl_num,
		a.trx_type,
		a.doc_ctrl_num,
		a.date_document,
		a.description,
		b.trx_type_cls_desc,
		a.cash_acct_code_from,
		a.amount_from,
		a.auto_rec_flag,
		1,
		0,
		a.from_org_id
FROM #cminpbtr_work a, cmtrxcls b
WHERE a.trx_type_cls_from = b.trx_type_cls
AND	  ((amount_from) > (0.0) + 0.0000001)
IF @@error != 0
	RETURN -1

INSERT #cmdetail
(
 trx_ctrl_num,
 trx_type,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 document1,
 account_code,
 amount,
 auto_rec_flag,
 cleared_type,
 flag,
 org_id
)
SELECT  a.trx_ctrl_num,
		a.trx_type,
		a.doc_ctrl_num,
		a.date_document,
		a.description,
		b.trx_type_cls_desc,
		a.cash_acct_code_to,
		a.amount_to,
		a.auto_rec_flag,
		0,
		0,
		a.to_org_id
FROM #cminpbtr_work a, cmtrxcls b
WHERE a.trx_type_cls_to = b.trx_type_cls
AND	  ((amount_to) > (0.0) + 0.0000001)
IF @@error != 0
	RETURN -1


INSERT #cmdetail
(
 trx_ctrl_num,
 trx_type,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 document1,
 account_code,
 amount,
 auto_rec_flag,
 cleared_type,
 flag,
 org_id
)
SELECT  a.trx_ctrl_num,
		a.trx_type,
		a.doc_ctrl_num + "_1",
		a.date_document,
		a.description,
		b.trx_type_cls_desc,
		a.cash_acct_code_from,
		a.bank_charge_amt_from,
		a.auto_rec_flag,
		b.cleared_type,
		0,
		a.from_org_id
FROM #cminpbtr_work a, cmtrxcls b
WHERE a.trx_type_cls_from = b.trx_type_cls
AND	  ((bank_charge_amt_from) > (0.0) + 0.0000001)
IF @@error != 0
	RETURN -1

INSERT #cmdetail
(
 trx_ctrl_num,
 trx_type,
 doc_ctrl_num,
 date_doc,
 trx_desc,
 document1,
 account_code,
 amount,
 auto_rec_flag,
 cleared_type,
 flag,
 org_id
)
SELECT  a.trx_ctrl_num,
		a.trx_type,
		a.doc_ctrl_num + "_1",
		a.date_document,
		a.description,
		b.trx_type_cls_desc,
		a.cash_acct_code_to,
		a.bank_charge_amt_to,
		a.auto_rec_flag,
		1,
		0,
		a.to_org_id
FROM #cminpbtr_work a, cmtrxcls b
WHERE a.trx_type_cls_to = b.trx_type_cls
AND	  ((bank_charge_amt_to) > (0.0) + 0.0000001)
IF @@error != 0
	RETURN -1



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtpcme.cpp" + ", line " + STR( 231, 5 ) + " -- MSG: " + "Process #cmdetail records"
WHILE (1=1)
   BEGIN
	  SELECT @trx_ctrl_num = NULL
	  SELECT @trx_ctrl_num = trx_ctrl_num,
			 @trx_type = trx_type,
			 @doc_ctrl_num = doc_ctrl_num,
			 @date_doc = date_doc,
			 @trx_desc = trx_desc,
			 @document1 = document1,
			 @account_code = account_code,
			 @amount = amount,
			 @auto_rec_flag = auto_rec_flag,
			 @cleared_type = cleared_type,
			 @org_id = org_id
	  FROM #cmdetail
	  WHERE id = @id

	  IF (@trx_ctrl_num IS NULL) BREAK

	  EXEC @result = cminpcr_sp
						 	7000,
							2,
							@trx_type,
							@trx_ctrl_num, 
							@doc_ctrl_num, 
		   					@date_doc, 
		   					@trx_desc,
		   					@document1,
		   					"", 
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
 
		SELECT @id = @id + 1

   END

DROP TABLE #cmdetail



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmbtpcme.cpp" + ", line " + STR( 283, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMBTProcessCMEntries_sp] TO [public]
GO
