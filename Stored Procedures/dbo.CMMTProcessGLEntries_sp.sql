SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[CMMTProcessGLEntries_sp]     @process_group_num varchar(16),
										@date_applied int,
										@batch_ctrl_num varchar(16),
										@user_id int,
										@journal_ctrl_num varchar(16) OUTPUT,
										@debug_level smallint = 0

AS

DECLARE    		@journal_type varchar(8),  
				@current_date int,
				@company_code varchar(8),
				@home_curr_code varchar(8),
				@account_code varchar(32),
				@amout float,
				@sequence_id int,
				@document_1 varchar(16),
				@trx_ctrl_num varchar(16),
				@reference_code varchar(32),
				@vendor_code varchar(12),
				@gl_desc varchar(40),
				@line_desc varchar(40),
				@gl_desc_def smallint,
				@result int,
				@amount float,
				@nat_cur_code varchar(8),
				@rate_type_home varchar(8),
				@rate_type_oper varchar(8),
				@rate_home float,
				@rate_oper float,
				@sq_id int,
				@rec_company_code varchar(8),
				@next_period int,
				@home_amount float,
				@oper_amount float,
				@home_precision smallint,
				@oper_precision smallint,
				@oper_curr_code varchar(8),
				@debug smallint,
				@ib_org_id varchar(30),
				@interbranch_flag smallint,
				@count_org_id 	int,
				@str_msg varchar(255)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpgle.cpp" + ", line " + STR( 81, 5 ) + " -- ENTRY: "


SELECT  @journal_type = journal_type
FROM    glappid
WHERE   app_id = 7000

SELECT @company_code = a.company_code, 
	   @home_curr_code = a.home_currency,
	   @oper_curr_code = a.oper_currency,
	   @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision,
	   @interbranch_flag = ib_flag
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code

EXEC appdate_sp @current_date OUTPUT

SELECT 	@ib_org_id = org_id 
FROM	#cmmanhdr_work
WHERE	batch_code = @batch_ctrl_num

IF @interbranch_flag = 1
BEGIN
	SELECT 	@count_org_id = COUNT(d.org_id)
	FROM	#cmmanhdr_work h,  #cmmandtl_work d
	WHERE	h.trx_ctrl_num 	= d.trx_ctrl_num
	AND	h.org_id 	!= d.org_id
	
	IF @count_org_id = 0
		SELECT 	@interbranch_flag = 0
END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpgle.cpp" + ", line " + STR( 119, 5 ) + " -- MSG: " + "Create GL Journal header record"

	EXEC appgetstring_sp "STR_CM_POST", @str_msg OUT

	EXEC 	@result = gltrxcrh_sp 
			@process_group_num,
			-1,
			7000, 
			2,
			@journal_type,
			@journal_ctrl_num OUTPUT,
			@str_msg,
			@current_date,
			@date_applied,
			0,
			0,
			0,
			@batch_ctrl_num,
			0,
			@company_code,
			@company_code, 
			@home_curr_code, 
			"", 
			7010,
			@user_id,
			0,			  
			@oper_curr_code,
			@debug,
			@ib_org_id,
			@interbranch_flag

IF @result <> 0
 	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpgle.cpp" + ", line " + STR( 154, 5 ) + " -- MSG: " + "Create GL Journal Detail record"
CREATE TABLE #gldetail
(
 account_code varchar(32),
 gl_desc varchar(40),
 trx_ctrl_num varchar(16),
 doc_ctrl_num varchar(16),
 reference_code varchar(32),
 amount float,
 nat_cur_code varchar(8),
 rate_type_home varchar(8),
 rate_type_oper varchar(8),
 rate_home float,
 rate_oper float,
 sequence_id int,
 flag smallint,
 org_id varchar (30) NULL
)

IF @@error != 0 
	RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpgle.cpp" + ", line " + STR( 179, 5 ) + " -- MSG: " + "credit the cash accts"
INSERT #gldetail
SELECT 	b.cash_acct_code,
		c.trx_type_cls_desc,
		a.trx_ctrl_num,
		a.doc_ctrl_num,
		b.reference_code,	
		-a.amount_natural,
		b.currency_code,
		b.rate_type_home,
		b.rate_type_home, 
		b.rate_home,
		b.rate_oper,
		a.sequence_id,
		0,
		b.org_id					
FROM #cmmandtl_work a, #cmmanhdr_work b, cmtrxcls c --, apaccts d
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.trx_type_cls = c.trx_type_cls





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpgle.cpp" + ", line " + STR( 203, 5 ) + " -- MSG: " + "debit the revenue accts"
INSERT #gldetail
SELECT 	a.account_code,
		c.trx_type_cls_desc,
		a.trx_ctrl_num,
		a.doc_ctrl_num,
		a.reference_code,
		a.amount_natural,
		b.currency_code,
		b.rate_type_home,
		b.rate_type_home, 
		b.rate_home,
		b.rate_oper,
		a.sequence_id,
		0,
		a.org_id
FROM #cmmandtl_work a, #cmmanhdr_work b, cmtrxcls c
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.trx_type_cls = c.trx_type_cls


CREATE TABLE #gldist
(
    journal_ctrl_num	varchar(16),
	rec_company_code	varchar(8),	
    account_code		varchar(32),	
	description		varchar(40),
    document_1		varchar(16), 	
    document_2		varchar(16), 	
	reference_code		varchar(32),	
    balance			float,		
	nat_balance		float,		
	nat_cur_code		varchar(8),	
	rate			float,		
	trx_type		smallint,
	seq_ref_id		int,		
    balance_oper            float NULL,
    rate_oper               float NULL,
    rate_type_home          varchar(8) NULL,
    rate_type_oper          varchar(8) NULL,
 org_id		varchar(30) NULL
)


INSERT #gldist
(
    	journal_ctrl_num ,
	rec_company_code,
    	account_code,
	description,
    	document_1,
    	document_2,
    	balance,		  
	reference_code,
	nat_balance,
	nat_cur_code,
	rate,
	trx_type,
	seq_ref_id,
    	balance_oper,
    	rate_oper,
    	rate_type_home,
    	rate_type_oper,
 	org_id
)
SELECT
 	@journal_ctrl_num,
 	@company_code,
 	account_code,
 	gl_desc,
 	doc_ctrl_num,
 	trx_ctrl_num,
 	(SIGN(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision)),
 	reference_code,
	amount,
 	nat_cur_code,
 	rate_home,
 	7010,
 	sequence_id,
 	(SIGN(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)),
 	rate_oper,
 	rate_type_home,
 	rate_type_oper,
	org_id
 
FROM #gldetail

EXEC @result = gltrxcdf_sp 7000, @debug_level

IF @result <> 0
 	RETURN -1





EXEC @result = gltrxvfy_sp	@journal_ctrl_num,
							@debug_level

IF (@result != 0)
	RETURN -11


DROP TABLE #gldetail
DROP TABLE #gldist

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "cmmtpgle.cpp" + ", line " + STR( 287, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMMTProcessGLEntries_sp] TO [public]
GO
