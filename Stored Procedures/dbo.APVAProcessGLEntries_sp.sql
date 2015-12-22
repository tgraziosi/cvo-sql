SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVAProcessGLEntries_sp]    @process_group_num varchar(16),
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
				@home_amount float,
				@oper_amount float,
				@home_precision smallint,
				@oper_precision smallint,
				@oper_curr_code varchar(8),
				@reference_code varchar(32),
				@org_id		varchar(30),		
                                @interbranch_flag	int,             
				@count_org_id		int,
				@str_msg	varchar(255)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "








SELECT  @journal_type = journal_type
FROM    glappid
WHERE   app_id = 4000

SELECT @company_code = a.company_code, 
	   @home_curr_code = a.home_currency,
	   @oper_curr_code = a.oper_currency,
	   @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision,
	   @interbranch_flag = a.ib_flag			
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code

SELECT @gl_desc_def = gl_desc_def
FROM apco

EXEC appdate_sp @current_date OUTPUT



SELECT 	@org_id	= org_id 
FROM	#apvachg_work
WHERE	batch_code = @batch_ctrl_num




IF @interbranch_flag = 1
BEGIN

	SELECT 	@count_org_id = COUNT(d.org_id)
	FROM	#apvachg_work h,  #apvacdt_work d
	WHERE	h.trx_ctrl_num 	= d.trx_ctrl_num
	AND	h.org_id 	!= d.org_id
	AND	d.gl_exp_acct 	!= d.new_gl_exp_acct 
	AND h.intercompany_flag =0
	
	IF @count_org_id = 0
		SELECT 	@interbranch_flag = 0

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Create #gldetail table"
CREATE TABLE #gldetail
(
 account_code varchar(32),
 vendor_code varchar(12),
 gl_desc varchar(40),
 rec_company_code varchar(8),
 doc_ctrl_num varchar(16),
 trx_ctrl_num varchar(16),
 reference_code varchar(32),
 amount float,
 nat_cur_code varchar(8),
 rate_type_home varchar(8),
 rate_type_oper varchar(8),
 rate_home float,
 rate_oper float,
 sequence_id int,
 flag smallint,
 org_id	varchar(30) NULL
)
IF @@error != 0 
	RETURN -1







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 155, 5 ) + " -- MSG: " + "Credit the old expense accounts"
INSERT #gldetail
SELECT 	a.gl_exp_acct,
		b.vendor_code,
		"",
		a.rec_company_code,
		b.doc_ctrl_num,
		b.trx_ctrl_num,
		a.reference_code,
		-(a.amt_extended + a.amt_discount + a.amt_freight + a.amt_tax + a.amt_misc + a.amt_nonrecoverable_tax),
		b.nat_cur_code,
		b.rate_type_home,
		b.rate_type_oper,
		b.rate_home,
		b.rate_oper,
		a.sequence_id,
		0,
		a.org_id
FROM #apvacdt_work a, #apvachg_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND (gl_exp_acct != new_gl_exp_acct
   OR rec_company_code != new_rec_company_code
   OR reference_code != new_reference_code )



  
DECLARE @curr_comp varchar(8),
		@curr_db_name varchar(128)
SET @curr_comp = ''
WHILE 1 = 1
BEGIN
	SET ROWCOUNT 1
	SELECT @curr_comp = e.company_code, @curr_db_name = e.db_name 
	FROM #gldetail b INNER JOIN ewcomp_vw e ON (e.company_code = b.rec_company_code)
	WHERE company_code > @curr_comp
	ORDER BY company_code ASC
	IF @@ROWCOUNT = 0
	begin
		SET ROWCOUNT 0 
		BREAK
	end
	SET ROWCOUNT 0 
	EXEC('UPDATE a SET org_id = x.organization_id
		FROM #gldetail a, ' + @curr_db_name + '..glchart x
		WHERE a.account_code = x.account_code
		AND a.rec_company_code = ''' + @curr_comp + '''
		')
	
END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 210, 5 ) + " -- MSG: " + "Debit the old expense accounts"
INSERT #gldetail
SELECT 	a.new_gl_exp_acct,
		b.vendor_code,
		"",
		a.new_rec_company_code,
		b.doc_ctrl_num,
		b.trx_ctrl_num,
		a.new_reference_code,
		a.amt_extended + a.amt_discount + a.amt_freight + a.amt_tax + a.amt_misc + a.amt_nonrecoverable_tax,
		b.nat_cur_code,
		b.rate_type_home,
		b.rate_type_oper,
		b.rate_home,
		b.rate_oper,
		a.sequence_id,
		0,
		a.org_id
FROM #apvacdt_work a, #apvachg_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND (gl_exp_acct != new_gl_exp_acct
   OR rec_company_code != new_rec_company_code
   OR reference_code != new_reference_code )


IF NOT EXISTS (SELECT * FROM #gldetail)
   BEGIN
	  DROP TABLE #gldetail	
	  SELECT @journal_ctrl_num = ""
	  RETURN 0
   END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 246, 5 ) + " -- MSG: " + "Create Journal header record"

	EXEC appgetstring_sp "STR_VOUCHER_ADJ_POST", @str_msg OUT

	EXEC 	@result = gltrxcrh_sp 
			@process_group_num,
			-1,
			4000, 
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
			4021,
			@user_id,
			0,			  
			@oper_curr_code,
			@debug_level,
			@org_id,		
			@interbranch_flag        

IF @result <> 0
 	RETURN -1



IF @gl_desc_def = 1
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 284, 5 ) + " -- MSG: " + "Get the vendor name"
	   UPDATE #gldetail
	   SET gl_desc = b.vendor_name
	   FROM #gldetail, apvend b
	   WHERE #gldetail.vendor_code = b.vendor_code

  	   IF @@error != 0 
			RETURN -1

   END



ELSE IF @gl_desc_def = 2
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 299, 5 ) + " -- MSG: " + "Get the vendor code/voucher num"
	   UPDATE #gldetail
	   SET gl_desc = a.vendor_code + '/' + c.apply_to_num
	   FROM #gldetail a, #apvacdt_work b, #apvachg_work c
	   WHERE a.trx_ctrl_num = b.trx_ctrl_num
           AND b.trx_ctrl_num = c.trx_ctrl_num
	   AND a.sequence_id = b.sequence_id
	   AND a.sequence_id > 0

  	   IF @@error != 0 
			RETURN -1

   END



ELSE IF @gl_desc_def = 3
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 317, 5 ) + " -- MSG: " + "Get the item_code"
	   UPDATE #gldetail
	   SET gl_desc = b.item_code
	   FROM #gldetail, #apvacdt_work b
	   WHERE #gldetail.trx_ctrl_num = b.trx_ctrl_num
	   AND #gldetail.sequence_id = b.sequence_id
	   AND #gldetail.sequence_id > 0

  	   IF @@error != 0 
			RETURN -1

   END
ELSE IF @gl_desc_def = 4
   BEGIN
       


	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 334, 5 ) + " -- MSG: " + "Get the item description"
	   UPDATE #gldetail
	   SET gl_desc = SUBSTRING(b.line_desc,1,40)  
	   FROM #gldetail, #apvacdt_work b
	   WHERE #gldetail.trx_ctrl_num = b.trx_ctrl_num
	   AND #gldetail.sequence_id = b.sequence_id
	   AND #gldetail.sequence_id > 0
       


  	   IF @@error != 0 
			RETURN -1

   END



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
 rec_company_code,
 account_code,
 gl_desc,
 doc_ctrl_num,
 trx_ctrl_num,
 (SIGN(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision)),
 reference_code,
 amount,
 nat_cur_code,
 rate_home,
 4021,
 sequence_id,
 (SIGN(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)),
 rate_oper,
 rate_type_home,
 rate_type_oper,
 org_id
FROM #gldetail
 

EXEC @result = gltrxcdf_sp 4000, @debug_level

IF @result <> 0
 	RETURN -1





EXEC @result = gltrxvfy_sp	@journal_ctrl_num,
							@debug_level

IF (@result != 0)
	RETURN -11


DROP TABLE #gldist
DROP TABLE #gldetail

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvapgle.cpp" + ", line " + STR( 414, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAProcessGLEntries_sp] TO [public]
GO
