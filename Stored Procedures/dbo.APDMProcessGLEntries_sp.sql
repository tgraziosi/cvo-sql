SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APDMProcessGLEntries_sp]    @process_group_num varchar(16),
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
				@sequence_id int,
				@document_1 varchar(16),
				@trx_ctrl_num varchar(16),
				@vendor_code varchar(12),
				@gl_desc varchar(40),
				@line_desc varchar(40),
				@gl_desc_def smallint,
				@result int,
				@amount float,
				@sq_id int,
				@rec_company_code varchar(8),
				@home_amount float,
				@oper_amount float,
				@home_precision smallint,
				@oper_precision smallint,
				@oper_curr_code varchar(8),
				@nat_cur_code	varchar(8),
				@reference_code varchar(32),
				@rate_type_home varchar(8),
				@rate_type_oper varchar(8),
				@rate_home float,
				@rate_oper float,
                                @org_id	varchar(30),                        	
                                @interbranch_flag	int,             	
				@count_org_id		int,
				@str_msg		varchar(255)


DECLARE @ib_offset SMALLINT, @ib_seg SMALLINT, @ib_length SMALLINT, @segment_length SMALLINT, @ib_flag smallint

SELECT @ib_offset = ib_offset, @ib_seg = ib_segment, @ib_length = ib_length, @ib_flag = ib_flag
FROM glco

--SELECT @segment_length = ISNULL(SUM(length),0)
--FROM glaccdef 
--WHERE acct_level < @ib_seg

-- scr 38330

  select @segment_length = ISNULL(start_col - 1, 0 ) from glaccdef where acct_level = @ib_seg 

-- end 38330


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 112, 5 ) + " -- ENTRY: "








SELECT  @journal_type = journal_type
FROM    glappid
WHERE   app_id = 4000

SELECT @company_code = a.company_code, 
	   @home_curr_code = a.home_currency,
	   @oper_curr_code = a.oper_currency,
	   @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision,
		@interbranch_flag = a.ib_flag	
FROM glco a
	INNER JOIN glcurr_vw b ON a.home_currency = b.currency_code
	INNER JOIN glcurr_vw c ON a.oper_currency = c.currency_code

SELECT @gl_desc_def = gl_desc_def
FROM apco

EXEC appdate_sp @current_date OUTPUT

SELECT 	@org_id	= org_id                         
FROM	#apdmchg_work
WHERE	batch_code = @batch_ctrl_num




IF @interbranch_flag = 1
BEGIN

	SELECT 	@count_org_id = COUNT(d.org_id)
	FROM	#apdmchg_work h
		INNER JOIN #apdmcdt_work d ON h.trx_ctrl_num = d.trx_ctrl_num AND h.org_id 	!= d.org_id
	WHERE h.intercompany_flag =0

	IF @count_org_id = 0
		SELECT 	@interbranch_flag = 0

END





EXEC appgetstring_sp "STR_DEBIT_MEMO_POST", @str_msg OUT

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 166, 5 ) + " -- MSG: " + "Create Journal header record"

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
			4092,
			@user_id,
			0,			  
			@oper_curr_code,
                        @debug_level,
                        @org_id,
                        @interbranch_flag                   

                           

IF @result <> 0
 	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 201, 5 ) + " -- MSG: " + "Create #gldetail table"
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
 org_id varchar(30) NULL        
)
IF @@error != 0 
	RETURN -1


CREATE INDEX TEMP_gldetail_ind1 ON #gldetail (trx_ctrl_num)




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 230, 5 ) + " -- MSG: " + "Credit the purchase return accounts"
INSERT #gldetail
SELECT 	a.gl_exp_acct,
		b.vendor_code,
		"",
		a.rec_company_code,
		b.doc_ctrl_num,
		b.trx_ctrl_num,
		a.reference_code,
		-(a.amt_extended - a.amt_discount + a.amt_freight + a.amt_tax + a.amt_misc),
		b.nat_cur_code,
		b.rate_type_home,
		b.rate_type_oper,
		b.rate_home,
		b.rate_oper,
		a.sequence_id,
		0,
                a.org_id        
FROM #apdmcdt_work a
	INNER JOIN #apdmchg_work b ON a.trx_ctrl_num = b.trx_ctrl_num



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 253, 5 ) + " -- MSG: " + "Debit the amount discount"
INSERT #gldetail
SELECT 	CASE WHEN @ib_flag = 0 THEN b.disc_given_acct_code 
			ELSE STUFF(b.disc_given_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		a.vendor_code,
		"",
		@company_code,
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		'',
		a.glamt_discount,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #apdmchg_work a
	INNER JOIN apaccts b ON a.posting_code = b.posting_code
	INNER JOIN Organization c ON a.org_id = c.organization_id
WHERE ((a.glamt_discount) > (0.0) + 0.0000001)

DECLARE @curr_comp varchar(8),
		@curr_db_name varchar(128)
SET @curr_comp = ''
WHILE 1 = 1
BEGIN
	SET ROWCOUNT 1
	SELECT @curr_comp = e.company_code, @curr_db_name = e.db_name 
	FROM #gldetail b INNER JOIN ewcomp_vw e ON (e.company_code = b.rec_company_code)
	WHERE company_code > @curr_comp
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


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 278, 5 ) + " -- MSG: " + "Credit the amount misc"
INSERT #gldetail
SELECT 	CASE WHEN @ib_flag = 0 THEN b.misc_chg_acct_code
		ELSE STUFF(b.misc_chg_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		a.vendor_code,
		"",
		@company_code,
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		'',
		-a.glamt_misc,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #apdmchg_work a
	INNER JOIN apaccts b ON a.posting_code = b.posting_code
	INNER JOIN Organization c ON a.org_id = c.organization_id
WHERE ((a.glamt_misc) > (0.0) + 0.0000001)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 303, 5 ) + " -- MSG: " + "Credit the amount tax"

INSERT #gldetail
SELECT 	CASE WHEN @ib_flag = 0 THEN b.sales_tax_acct_code
		ELSE STUFF(b.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		a.vendor_code,
		"",
		@company_code,
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		'',
		-a.glamt_tax,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #apdmchg_work a
	INNER JOIN apaccts b ON a.posting_code = b.posting_code
	INNER JOIN Organization c ON a.org_id = c.organization_id
WHERE a.amt_tax != a.glamt_tax			
AND ((a.glamt_tax) > (0.0) + 0.0000001)


INSERT #gldetail
SELECT 	DISTINCT
	CASE	
		WHEN	RTRIM(LTRIM(d.sales_tax_acct_code)) = '' THEN 
			CASE WHEN @ib_flag = 0 THEN e.sales_tax_acct_code
				ELSE STUFF(e.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, f.branch_account_number)	END	
		ELSE	
			CASE WHEN @ib_flag = 0 THEN d.sales_tax_acct_code
				ELSE STUFF(d.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, f.branch_account_number)	END
	END, 
	b.vendor_code,
	"",
	@company_code,
	b.doc_ctrl_num,
	b.trx_ctrl_num,
	'',
	-1 * c.amt_final_tax,			
	b.nat_cur_code,
 	b.rate_type_home,
	b.rate_type_oper,
	b.rate_home,
	b.rate_oper,
	0,
	0,
        b.org_id        
FROM 	#apdmchg_work b
	INNER JOIN apinptax c ON b.trx_ctrl_num = c.trx_ctrl_num AND b.trx_type = c.trx_type
	INNER JOIN aptxtype d ON c.tax_type_code = d.tax_type_code
	INNER JOIN apaccts e ON b.posting_code = e.posting_code
	INNER JOIN Organization f ON b.org_id = f.organization_id
WHERE b.amt_tax = b.glamt_tax			
AND c.amt_final_tax <> 0.0
AND	d.recoverable_flag = 1
AND	d.tax_based_type <> 2






EXEC appgetstring_sp 'STR_NO_RECOVER_TAX', @str_msg OUT

INSERT #gldetail
SELECT 	DISTINCT
	CASE WHEN @ib_flag = 0 THEN e.freight_acct_code
	ELSE STUFF(e.freight_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
	b.vendor_code,
	@str_msg,
	@company_code,
	b.doc_ctrl_num,
	b.trx_ctrl_num,
	'',
	-b.tax_freight_no_recoverable,
	b.nat_cur_code,
 	b.rate_type_home,
	b.rate_type_oper,
	b.rate_home,
	b.rate_oper,
	0,
	0,
	b.org_id
FROM 	#apdmchg_work b
	INNER JOIN apaccts e ON b.posting_code = e.posting_code
	INNER JOIN Organization c ON b.org_id = c.organization_id
WHERE b.tax_freight_no_recoverable <> 0.0


INSERT #gldetail
SELECT 	DISTINCT
	CASE WHEN @ib_flag = 0 THEN d.sales_tax_acct_code
	ELSE STUFF(d.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, f.branch_account_number) END, 
	b.vendor_code,
	"",
	@company_code,
	b.doc_ctrl_num,
	b.trx_ctrl_num,
	'',
	-c.amt_final_tax,			
	b.nat_cur_code,
 	b.rate_type_home,
	b.rate_type_oper,
	b.rate_home,
	b.rate_oper,
	0,
	0,
	b.org_id
FROM 	#apdmchg_work b
	INNER JOIN apinptax c ON b.trx_ctrl_num = c.trx_ctrl_num AND b.trx_type = c.trx_type
	INNER JOIN artxtype d ON c.tax_type_code = d.tax_type_code
	INNER JOIN apaccts e ON b.posting_code = e.posting_code
	INNER JOIN Organization f ON b.org_id = f.organization_id
WHERE b.amt_tax = b.glamt_tax				
AND c.amt_final_tax <> 0.0
AND	d.recoverable_flag = 1
AND	d.tax_based_type = 2


--
-- Summarize non-recoverable taxes by transaction and account_code
--
DECLARE @sumtax TABLE(
	trx_ctrl_num		varchar(16),
	trx_type		integer,
	account_code		varchar(32),
	amt_final_tax		float,
	reference_code          varchar(32) NULL				
)

 INSERT @sumtax
 SELECT t.trx_ctrl_num, t.trx_type, t.account_code, amt_final_tax=SUM(t.amt_final_tax), d.reference_code 
  FROM #apdmtaxdtl_work t
	INNER JOIN #apdmchg_work h ON t.trx_ctrl_num = h.trx_ctrl_num AND t.trx_type = h.trx_type
	INNER JOIN #apdmcdt_work d ON t.trx_ctrl_num = d.trx_ctrl_num AND t.trx_type = d.trx_type AND t.detail_sequence_id =  d.sequence_id 
 WHERE t.recoverable_flag = 0
 GROUP BY t.trx_ctrl_num, t.trx_type, t.account_code, d.reference_code				

--
-- Create GL Details for non-recoverable taxes
--
INSERT #gldetail
SELECT 	DISTINCT
	t.account_code,
	b.vendor_code,
	@str_msg,
	@company_code,
	b.doc_ctrl_num,
	b.trx_ctrl_num,
	t.reference_code,								
	-1 * t.amt_final_tax,			
	b.nat_cur_code,
 	b.rate_type_home,
	b.rate_type_oper,
	b.rate_home,
	b.rate_oper,
	0,
	0,
	b.org_id
FROM 	#apdmchg_work b
	INNER JOIN @sumtax t ON b.trx_ctrl_num = t.trx_ctrl_num AND	b.trx_type = t.trx_type
WHERE t.amt_final_tax <> 0.0



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 473, 5 ) + " -- MSG: " + "hit the tax included rounding account"
SELECT 	a.trx_ctrl_num,
	 	calc_tax = SUM(b.calc_tax * c.tax_included_flag)
INTO 	 #amttaxincl
FROM #apdmchg_work a
	INNER JOIN #apdmcdt_work b ON a.trx_ctrl_num = b.trx_ctrl_num
	INNER JOIN aptax c ON b.tax_code = c.tax_code
GROUP BY a.trx_ctrl_num


INSERT #gldetail
SELECT 	CASE WHEN @ib_flag = 0 THEN b.tax_rounding_acct
		ELSE STUFF(b.tax_rounding_acct,@ib_offset + @segment_length ,@ib_length, d.branch_account_number) END, 
		a.vendor_code,
		"",
		@company_code,
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		'',
		-( c.calc_tax - a.amt_tax_included ),
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id              
FROM #apdmchg_work a
	INNER JOIN apaccts b ON a.posting_code = b.posting_code
	INNER JOIN #amttaxincl c ON a.trx_ctrl_num = c.trx_ctrl_num
	INNER JOIN Organization d ON a.org_id = d.organization_id
WHERE (ABS((c.calc_tax)-(a.amt_tax_included)) > 0.0000001)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 508, 5 ) + " -- MSG: " + "Credit the amount freight"
INSERT #gldetail
SELECT 	CASE WHEN @ib_flag = 0 THEN b.freight_acct_code
		ELSE STUFF(b.freight_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		a.vendor_code,
		"",
		@company_code,
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		'',
		-a.glamt_freight,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #apdmchg_work a
	INNER JOIN apaccts b ON a.posting_code = b.posting_code
	INNER JOIN Organization c ON a.org_id = c.organization_id
WHERE ((a.glamt_freight) > (0.0) + 0.0000001)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 533, 5 ) + " -- MSG: " + "Debit the DM on-acct code"
INSERT #gldetail
SELECT 	CASE WHEN @ib_flag = 0 THEN b.dm_on_acct_code
		ELSE STUFF(b.dm_on_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		a.vendor_code,
		"",
		@company_code,
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		'',
		a.amt_net,
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #apdmchg_work a
	INNER JOIN apaccts b ON a.posting_code = b.posting_code
	INNER JOIN Organization c ON a.org_id = c.organization_id
WHERE ((a.amt_net) > (0.0) + 0.0000001)




IF @gl_desc_def = 1
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 562, 5 ) + " -- MSG: " + "Set GL Detail Desc to Vendor Name"
	   UPDATE #gldetail
	   SET gl_desc = b.vendor_name
	   FROM #gldetail
		INNER JOIN apvend b ON #gldetail.vendor_code = b.vendor_code

  	   IF @@error != 0 
			RETURN -1
   END
ELSE IF @gl_desc_def = 2
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 573, 5 ) + " -- MSG: " + "Set GL Detail Desc to Vendor Code/Invoice No"
	   UPDATE #gldetail
	   SET gl_desc = vendor_code + '/' + doc_ctrl_num
  	   IF @@error != 0 
			RETURN -1

   END
ELSE IF @gl_desc_def = 3
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 582, 5 ) + " -- MSG: " + "Set GL Detail Desc to Vendor Code/Item Code"
	   UPDATE #gldetail
	   SET gl_desc = SUBSTRING(#gldetail.vendor_code + "/" + b.item_code,1,40)
	   FROM #gldetail
		INNER JOIN #apdmcdt_work b ON #gldetail.trx_ctrl_num = b.trx_ctrl_num AND #gldetail.sequence_id = b.sequence_id
	   WHERE #gldetail.sequence_id > 0

  	   IF @@error != 0 
			RETURN -1

   END
ELSE IF @gl_desc_def = 4
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 595, 5 ) + " -- MSG: " + "Set GL Detail Desc to Vendor Code/Item Description"
	   UPDATE #gldetail
	   SET gl_desc = SUBSTRING(#gldetail.vendor_code + "/" + b.line_desc,1,40)
	   FROM #gldetail
		INNER JOIN #apdmcdt_work b ON #gldetail.trx_ctrl_num = b.trx_ctrl_num AND #gldetail.sequence_id = b.sequence_id
	   WHERE #gldetail.sequence_id > 0

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
 account_code,   --SCR # 050376 / RiGarcia / 06-26-2008
 gl_desc,
 doc_ctrl_num,
 trx_ctrl_num,
 (SIGN(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision)),
 reference_code,
 amount,
 nat_cur_code,
 rate_home,
 4092,
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


DROP TABLE #gldist




EXEC @result = gltrxvfy_sp	@journal_ctrl_num,
							@debug_level

IF (@result != 0)
	RETURN -11



DROP TABLE #gldetail

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpgle.cpp" + ", line " + STR( 675, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMProcessGLEntries_sp] TO [public]
GO
