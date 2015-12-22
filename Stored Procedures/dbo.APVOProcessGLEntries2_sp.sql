SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                

CREATE PROC [dbo].[APVOProcessGLEntries2_sp]   --use by matchig proccess 
 										@process_group_num varchar(16),
										@date_applied int,
										@batch_ctrl_num varchar(16),
										@user_id int,
										@journal_ctrl_num varchar(16) OUTPUT,
										@debug_level smallint = 0

AS

DECLARE    			@journal_type varchar(8),  
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
				@accrual_journal_ctrl_num varchar(16),
				@credit_invoice_flag smallint,	
				@org_id		varchar(30), 
                                @interbranch_flag 	int,            
				@count_org_id 	int,
				@old_org_id varchar(30),
				@min_org_id varchar(30),
				@str_msg_at VARCHAR(255)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 104, 5 ) + ' -- ENTRY: '


SELECT 	@credit_invoice_flag 	= credit_invoice_flag,
	@gl_desc_def 		= gl_desc_def
FROM 	apco

SELECT  @journal_type = journal_type
FROM    glappid
WHERE   app_id = 4000

SELECT 	@company_code = a.company_code, 
	@home_curr_code = a.home_currency,
	@oper_curr_code = a.oper_currency,
	@home_precision = b.curr_precision,
	@oper_precision = c.curr_precision,
	@interbranch_flag = ib_flag
FROM 	glco a
	INNER JOIN glcurr_vw b on a.home_currency = b.currency_code
	INNER JOIN glcurr_vw c on a.oper_currency = c.currency_code


EXEC appdate_sp @current_date OUTPUT

--SELECT  @date_applied = @current_date


--ciclo por organizaciones
select @org_id = ''
while ( 1 = 1)
BEGIN
	SELECT  @old_org_id = @org_id

	SELECT  @min_org_id = min(org_id)					
	FROM    #apvochg_work --#apvochg_work #apvocdt_work
	WHERE   org_id > @old_org_id						

	SELECT  @org_id = org_id
	FROM    #apvochg_work --#apvochg_work #apvocdt_work
	WHERE   org_id > @old_org_id
	AND	org_id = @min_org_id						

	
	
	
	IF  @org_id !> @old_org_id
		break
	
	SELECT  @interbranch_flag = ib_flag
	FROM 	glco 

	IF @interbranch_flag = 1
	BEGIN
		

		SELECT 	@count_org_id = COUNT(d.org_id)
		FROM	#apvochg_work h
			INNER JOIN #apvocdt_work d ON h.trx_ctrl_num = d.trx_ctrl_num AND h.org_id 	!= d.org_id
		WHERE	h.intercompany_flag =0
		AND h.org_id = @org_id --GGR

		
		
		IF @count_org_id = 0
			SELECT 	@interbranch_flag = 0
	
	END
	
	

	
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 156, 5 ) + ' -- MSG: ' + 'Create Journal header record'

		EXEC appgetstring_sp 'STR_FROM_MATCHAP_ACCRUALS', @str_msg_at  OUT		
		
		EXEC 	@result = gltrxcrh1_sp 				--GGR
				@process_group_num,
				0,					--GGR POSTED FLAG
				4000, 
				2,
				@journal_type,
				@journal_ctrl_num OUTPUT,
				@str_msg_at,
				@current_date,
				@date_applied,
				0,
				0,
				1,					--Reversing ON
				@batch_ctrl_num,
				5,					--GGR
				@company_code,
				@company_code, 
				@home_curr_code, 
				'', 
				4091,
				@user_id,
				0,			  
				@oper_curr_code,
				@debug_level,
				@org_id,		
				@interbranch_flag		
	
	IF @result <> 0
	 	RETURN -1
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 189, 5 ) + ' -- MSG: ' + 'Create #gldetail table'
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
	
	CREATE INDEX TEMP_gldetail_ind0 ON #gldetail (trx_ctrl_num)
	
	
	
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 218, 5 ) + ' -- MSG: ' + 'Debit the expense accounts'
	INSERT #gldetail
	SELECT 	a.gl_exp_acct,
			b.vendor_code,
			'',
			a.rec_company_code,
			b.doc_ctrl_num,
			b.trx_ctrl_num,
			a.reference_code,
			ROUND(a.amt_extended,6) - ROUND(a.amt_discount,6) + ROUND(a.amt_freight,6) + ROUND(a.amt_tax,6) + ROUND(a.amt_misc,6),
			--a.amt_extended,
			b.nat_cur_code,
			b.rate_type_home,
			b.rate_type_oper,
			b.rate_home,
			b.rate_oper,
			a.sequence_id,
			0,
			a.org_id
	FROM #apvocdt_work a
		INNER JOIN #apvochg_work b ON a.trx_ctrl_num = b.trx_ctrl_num
	where 	b.org_id = @org_id   --ggr

	
	
	
	--- RMV 
	declare @ib_offset smallint, @ib_seg smallint, @ib_length smallint, @segment_length smallint, @ib_flag smallint
	select @ib_offset = ib_offset, @ib_seg = ib_segment, @ib_length = ib_length, @ib_flag = ib_flag
	from glco
	
	--select @segment_length = ISNULL(sum(length),0) from glaccdef where acct_level < @ib_seg   --- AC update to correct use of length
	--select @segment_length = ISNULL(max(length),0) from glaccdef where acct_level < @ib_seg      --- AC update to correct use of length
	
	-- scr 38330
	
	  select @segment_length = ISNULL(start_col - 1, 0 ) from glaccdef where acct_level = @ib_seg 
	
	-- end 38330
	
	
	
	IF ((select top 1 isnull( b.a_disc_given_acct_code,1)
                FROM #apvochg_work a	
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER join Organization c ON a.org_id = c.organization_id
	WHERE (ABS((a.glamt_discount)-(0.0)) > 0.0000001)
	and 	a.org_id = @org_id
	and     b.a_disc_given_acct_code is null ) > 0  )
	begin
		RETURN 420
	end
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 245, 5 ) + ' -- MSG: ' + 'Credit the amount discount'
	INSERT #gldetail
	SELECT 	--dbo.IBAcctMask_fn(b.disc_given_acct_code,a.org_id), 
			CASE WHEN @ib_flag = 0 THEN b.a_disc_given_acct_code
			ELSE STUFF(b.a_disc_given_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
			a.vendor_code,
			'',
			@company_code,
			a.doc_ctrl_num,
			a.trx_ctrl_num,
			'',
			-a.glamt_discount,
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			a.rate_home,
			a.rate_oper,
			0,
			0,
			a.org_id
	FROM #apvochg_work a	
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		inner join Organization c ON a.org_id = c.organization_id
	WHERE (ABS((a.glamt_discount)-(0.0)) > 0.0000001)
	and 	a.org_id = @org_id   --ggr
	
	
	IF ((select top 1 isnull(b.a_misc_chg_acct_code,1)
                FROM #apvochg_work a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		inner join Organization c ON a.org_id = c.organization_id
	WHERE (ABS((a.glamt_misc)-(0.0)) > 0.0000001) 
	and 	a.org_id = @org_id 
	and     b.a_misc_chg_acct_code is null	 ) > 0  )
	begin
		RETURN 420
	end
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 274, 5 ) + ' -- MSG: ' + 'debit the amount misc'
	INSERT #gldetail
	SELECT 	--dbo.IBAcctMask_fn(b.misc_chg_acct_code,a.org_id), 
			CASE WHEN @ib_flag = 0 THEN b.a_misc_chg_acct_code
			ELSE STUFF(b.a_misc_chg_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
			a.vendor_code,
			'',
			@company_code,
			a.doc_ctrl_num,
			a.trx_ctrl_num,
			'',
			a.glamt_misc,
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			a.rate_home,
			a.rate_oper,
			0,
			0,
			a.org_id
	FROM #apvochg_work a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		inner join Organization c ON a.org_id = c.organization_id
	WHERE (ABS((a.glamt_misc)-(0.0)) > 0.0000001) 
	and 	a.org_id = @org_id   --ggr
	
	IF ((select top 1 isnull(b.a_sales_tax_acct_code,1)
                FROM #apvochg_work a	
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN Organization c ON a.org_id = c.organization_id
		WHERE a.amt_tax != a.glamt_tax			
		AND ((a.glamt_tax) > (0.0) + 0.0000001)
		and 	a.org_id = @org_id 
		and     b.a_sales_tax_acct_code is null  ) > 0  )
	begin
		RETURN 420
	end
			
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 312, 5 ) + ' -- MSG: ' + 'Debit the amount tax'
	INSERT #gldetail
	SELECT 	--dbo.IBAcctMask_fn(b.sales_tax_acct_code,a.org_id),
			CASE WHEN @ib_flag = 0 THEN b.a_sales_tax_acct_code
			ELSE STUFF(b.a_sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
			a.vendor_code,
			'',
			@company_code,
			a.doc_ctrl_num,
			a.trx_ctrl_num,
			'',
			a.glamt_tax,
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			a.rate_home,
			a.rate_oper,
			0,
			0,
			a.org_id
		FROM #apvochg_work a	
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN Organization c ON a.org_id = c.organization_id
		WHERE a.amt_tax != a.glamt_tax			
		AND ((a.glamt_tax) > (0.0) + 0.0000001)
		and 	a.org_id = @org_id   --ggr
	
	
	
	IF ((select top 1 isnull(e.a_sales_tax_acct_code ,1)
               FROM #apvochg_work b
			INNER JOIN mtinptax c ON b.trx_ctrl_num = c.match_ctrl_num AND b.trx_type = c.trx_type
			INNER JOIN artxtype d ON c.tax_type_code = d.tax_type_code
			INNER JOIN apaccts e ON b.posting_code = e.posting_code
			INNER JOIN Organization f ON b.org_id = f.organization_id		
		WHERE 	b.amt_tax = b.glamt_tax				
		AND 	c.amt_final_tax <> 0.0
		AND	d.recoverable_flag = 1
		AND	d.tax_based_type <> 2
		and 	b.org_id = @org_id 
		and     e.a_sales_tax_acct_code is null   ) > 0  )
	begin
		RETURN 420
	end
	
	
	
	
	
	INSERT #gldetail
	SELECT 	DISTINCT
		CASE	
			WHEN	RTRIM(LTRIM(d.sales_tax_acct_code)) = '' THEN 
				CASE WHEN @ib_flag = 0 THEN e.a_sales_tax_acct_code
					ELSE STUFF( e.a_sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, f.branch_account_number) END
			ELSE
				CASE WHEN @ib_flag = 0 THEN d.sales_tax_acct_code
					ELSE STUFF( d.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, f.branch_account_number) END
		END,  
		b.vendor_code,
		'',
		@company_code,
		b.doc_ctrl_num,
		b.trx_ctrl_num,
		'',
		c.amt_final_tax,			
		b.nat_cur_code,
	 	b.rate_type_home,
		b.rate_type_oper,
		b.rate_home,
		b.rate_oper,
		0,
		c.sequence_id,
		b.org_id
	FROM #apvochg_work b
			INNER JOIN mtinptax c ON b.trx_ctrl_num = c.match_ctrl_num AND b.trx_type = c.trx_type
			INNER JOIN artxtype d ON c.tax_type_code = d.tax_type_code
			INNER JOIN apaccts e ON b.posting_code = e.posting_code
			INNER JOIN Organization f ON b.org_id = f.organization_id		
	WHERE 	b.amt_tax = b.glamt_tax				
	AND 	c.amt_final_tax <> 0.0
	AND	d.recoverable_flag = 1
	AND	d.tax_based_type <> 2
	and 	b.org_id = @org_id   --ggr

	
	EXEC appgetstring_sp 'STR_NO_RECOVER_TAX', @str_msg_at  OUT

	IF ((select top 1 isnull(e.a_freight_acct_code ,1)
               FROM 	#apvochg_work b
			INNER JOIN apaccts e ON b.posting_code = e.posting_code
			INNER JOIN Organization c ON b.org_id = c.organization_id
	WHERE 	b.tax_freight_no_recoverable <> 0.0
	and 	b.org_id = @org_id
	and     e.a_freight_acct_code is null ) > 0  )
	begin
		RETURN 420
	end
	
	INSERT #gldetail
	SELECT 	DISTINCT
	--	dbo.IBAcctMask_fn( e.freight_acct_code,b.org_id),
		CASE WHEN @ib_flag = 0 THEN e.a_freight_acct_code
		ELSE STUFF(e.a_freight_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
		b.vendor_code,
		@str_msg_at,
		@company_code,
		b.doc_ctrl_num,
		b.trx_ctrl_num,
		'',
		b.tax_freight_no_recoverable,
		b.nat_cur_code,
	 	b.rate_type_home,
		b.rate_type_oper,
		b.rate_home,
		b.rate_oper,
		0,
		0,
		b.org_id
	FROM 	#apvochg_work b
			INNER JOIN apaccts e ON b.posting_code = e.posting_code
			INNER JOIN Organization c ON b.org_id = c.organization_id
	WHERE 	b.tax_freight_no_recoverable <> 0.0
	and 	b.org_id = @org_id   --ggr
	
	IF ((select top 1 isnull( d.sales_tax_acct_code,1)
               FROM 	#apvochg_work b
			INNER JOIN mtinptax c ON b.trx_ctrl_num = c.match_ctrl_num AND b.trx_type = c.trx_type
			INNER JOIN artxtype d ON c.tax_type_code = d.tax_type_code
			INNER JOIN apaccts e ON b.posting_code = e.posting_code
			INNER JOIN Organization f ON b.org_id = f.organization_id
	WHERE b.amt_tax = b.glamt_tax				
	AND 	c.amt_final_tax <> 0.0
	AND	d.recoverable_flag = 1
	AND	d.tax_based_type = 2
	and 	b.org_id = @org_id
	and     d.sales_tax_acct_code is null ) > 0  )
	begin
		RETURN 420
	end
	
	INSERT #gldetail
	SELECT 	DISTINCT
	--	dbo.IBAcctMask_fn( d.sales_tax_acct_code,b.org_id),
		CASE WHEN @ib_flag = 0 THEN d.sales_tax_acct_code 
		ELSE STUFF(d.sales_tax_acct_code ,@ib_offset + @segment_length ,@ib_length, f.branch_account_number) END, 
		b.vendor_code,
		'',
		@company_code,
		b.doc_ctrl_num,
		b.trx_ctrl_num,
		'',
		c.amt_final_tax,			
		b.nat_cur_code,
	 	b.rate_type_home,
		b.rate_type_oper,
		b.rate_home,
		b.rate_oper,
		0,
		c.sequence_id,
		b.org_id
	FROM 	#apvochg_work b
			INNER JOIN mtinptax c ON b.trx_ctrl_num = c.match_ctrl_num AND b.trx_type = c.trx_type
			INNER JOIN artxtype d ON c.tax_type_code = d.tax_type_code
			INNER JOIN apaccts e ON b.posting_code = e.posting_code
			INNER JOIN Organization f ON b.org_id = f.organization_id
	WHERE b.amt_tax = b.glamt_tax				
	AND 	c.amt_final_tax <> 0.0
	AND	d.recoverable_flag = 1
	AND	d.tax_based_type = 2
	and 	b.org_id = @org_id   --ggr

	
	
	

	--
	-- Summarize non-recoverable taxes by transaction and account_code
	--
	DECLARE @sumtax TABLE(
		trx_ctrl_num		varchar(16),
		trx_type		integer,
		amt_final_tax		float,
		account_code		varchar(32),
		rec_company_code	varchar(8),
		org_id		varchar(30) NULL,
		reference_code  varchar(32) NULL												
	)
	
	 INSERT @sumtax
	 SELECT t.trx_ctrl_num, t.trx_type, amt_final_tax=SUM(t.amt_final_tax), t.account_code,  d.rec_company_code, d.org_id, d.reference_code     
	  FROM #apvotaxdtl_work t
		INNER JOIN #apvochg_work h ON t.trx_ctrl_num = h.trx_ctrl_num AND t.trx_type = h.trx_type
		INNER JOIN #apvocdt_work d ON t.trx_ctrl_num = d.trx_ctrl_num AND t.trx_type = d.trx_type AND t.detail_sequence_id =  d.sequence_id
	 WHERE t.recoverable_flag = 0 --0
	 GROUP BY t.trx_ctrl_num, t.trx_type, t.account_code, d.rec_company_code, d.org_id, d.reference_code					

	

	
	
	
	
	
	--
	-- Create GL Details for non-recoverable taxes
	--
	INSERT #gldetail
	SELECT 	DISTINCT
		t.account_code,
		b.vendor_code,
		@str_msg_at,
		t.rec_company_code,
		b.doc_ctrl_num,
		b.trx_ctrl_num,
		t.reference_code,														
		t.amt_final_tax,			
		b.nat_cur_code,
	 	b.rate_type_home,
		b.rate_type_oper,
		b.rate_home,
		b.rate_oper,
		0,
		0,
		t.org_id
	FROM 	#apvochg_work b
		INNER JOIN @sumtax t ON b.trx_ctrl_num = t.trx_ctrl_num AND	b.trx_type = t.trx_type
	WHERE t.amt_final_tax <> 0.0
	and 	b.org_id = @org_id   --ggr
	
	
	
	
	
	 
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 494, 5 ) + ' -- MSG: ' + 'hit the tax included rounding account'
	SELECT 	a.trx_ctrl_num,
		 	calc_tax = SUM(b.calc_tax * c.tax_included_flag)
	INTO 	 #amttaxincl
	FROM #apvochg_work a
		INNER JOIN #apvocdt_work b ON a.trx_ctrl_num = b.trx_ctrl_num
		INNER JOIN aptax c ON b.tax_code = c.tax_code
	GROUP BY a.trx_ctrl_num

	IF ((select top 1 isnull( b.a_tax_rounding_acct,1)
               FROM #apvochg_work a
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN #amttaxincl c ON a.trx_ctrl_num = c.trx_ctrl_num
			INNER JOIN Organization d ON a.org_id = d.organization_id
	WHERE (ABS((c.calc_tax)-(a.amt_tax_included)) > 0.0000001)
	and 	a.org_id = @org_id
	and     b.a_tax_rounding_acct is null ) > 0  )
	begin
		RETURN 420
	end
	
	INSERT #gldetail
	SELECT 	--dbo.IBAcctMask_fn( b.tax_rounding_acct,a.org_id),
			CASE WHEN @ib_flag = 0 THEN b.a_tax_rounding_acct
			ELSE STUFF(b.a_tax_rounding_acct,@ib_offset + @segment_length ,@ib_length, d.branch_account_number) END, 
			a.vendor_code,
			'',
			@company_code,
			a.doc_ctrl_num,
			a.trx_ctrl_num,
			'',
			c.calc_tax - a.amt_tax_included,
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			a.rate_home,
			a.rate_oper,
			0,
			0,
			a.org_id
	FROM #apvochg_work a
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN #amttaxincl c ON a.trx_ctrl_num = c.trx_ctrl_num
			INNER JOIN Organization d ON a.org_id = d.organization_id
	WHERE (ABS((c.calc_tax)-(a.amt_tax_included)) > 0.0000001)
	and 	a.org_id = @org_id   --ggr
	
	
	IF ((select top 1 isnull( b.a_freight_acct_code,1)
               FROM #apvochg_work a
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN Organization c ON a.org_id = c.organization_id
	AND (ABS((a.glamt_freight)-(0.0)) > 0.0000001)
	and 	a.org_id = @org_id 
	and     b.a_freight_acct_code is null ) > 0  )
	begin
		RETURN 420
	end	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 529, 5 ) + ' -- MSG: ' + 'Debit the amount freight'
	INSERT #gldetail
	SELECT 	--dbo.IBAcctMask_fn( b.freight_acct_code,a.org_id),
			CASE WHEN @ib_flag = 0 THEN b.a_freight_acct_code
			ELSE STUFF(b.a_freight_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
			a.vendor_code,
			'',
			@company_code,
			a.doc_ctrl_num,
			a.trx_ctrl_num,
			'',
			a.glamt_freight,
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			a.rate_home,
			a.rate_oper,
			0,
			0,
			a.org_id
	FROM #apvochg_work a
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN Organization c ON a.org_id = c.organization_id
	AND (ABS((a.glamt_freight)-(0.0)) > 0.0000001)
	and 	a.org_id = @org_id   --ggr
	
	
	
	
	
	IF ((select top 1 isnull(b.a_ap_acct_code,1)
               FROM #apvochg_work a
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN Organization c ON a.org_id = c.organization_id
	WHERE ( ((a.amt_net) > (0.0) + 0.0000001) OR a.amt_net = 0.0 )
	AND @credit_invoice_flag = 0
	and 	a.org_id = @org_id 
	and     b.a_ap_acct_code is null ) > 0  )
	begin
		RETURN 420
	end
	
	
	
	
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 564, 5 ) + ' -- MSG: ' + 'credit the ap-acct code'
	INSERT #gldetail
	SELECT 	--dbo.IBAcctMask_fn( b.ap_acct_code,a.org_id),
			CASE WHEN @ib_flag = 0 THEN b.a_ap_acct_code
			ELSE STUFF(b.a_ap_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
			a.vendor_code,
			'',
			@company_code,
			a.doc_ctrl_num,
			a.trx_ctrl_num,
			'',
			-a.amt_net,
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			a.rate_home,
			a.rate_oper,
			0,
			0,
			a.org_id
	FROM #apvochg_work a
			INNER JOIN apaccts b ON a.posting_code = b.posting_code
			INNER JOIN Organization c ON a.org_id = c.organization_id
	WHERE ( ((a.amt_net) > (0.0) + 0.0000001) OR a.amt_net = 0.0 )
	AND @credit_invoice_flag = 0
	and 	a.org_id = @org_id   --ggr 




























	
	IF ((select top 1 isnull( b.a_ap_acct_code,1)
               FROM #apvochg_work a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id
	WHERE @credit_invoice_flag = 1
	and 	a.org_id = @org_id 
	and     b.a_ap_acct_code is null ) > 0  )
	begin
		RETURN 420
	end	
	
	
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 593, 5 ) + ' -- MSG: ' + 'credit the ap-acct code'
	INSERT #gldetail
	SELECT 	--dbo.IBAcctMask_fn( b.ap_acct_code,a.org_id),
			CASE WHEN @ib_flag = 0 THEN b.a_ap_acct_code
			ELSE STUFF(b.a_ap_acct_code, @ib_offset + @segment_length ,@ib_length, c.branch_account_number) END, 
			a.vendor_code,
			'',
			@company_code,
			a.doc_ctrl_num,
			a.trx_ctrl_num,
			'',
			-a.amt_net,
			a.nat_cur_code,
			a.rate_type_home,
			a.rate_type_oper,
			a.rate_home,
			a.rate_oper,
			0,
			0,
			a.org_id
	FROM #apvochg_work a
		INNER JOIN apaccts b ON a.posting_code = b.posting_code
		INNER JOIN Organization c ON a.org_id = c.organization_id
	WHERE @credit_invoice_flag = 1
	and 	a.org_id = @org_id   --ggr  
	
	
	
	IF @gl_desc_def = 1
	   BEGIN
		   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 621, 5 ) + ' -- MSG: ' + 'Get the vendor name'
		   UPDATE #gldetail
		   SET gl_desc = b.vendor_name
		   FROM #gldetail
			INNER JOIN apvend b ON #gldetail.vendor_code = b.vendor_code
			
		  
	  	   --IF @@error != 0 
				--RETURN -1
	
	   END
	ELSE IF @gl_desc_def = 2
	   BEGIN
		   UPDATE #gldetail
		   SET gl_desc = vendor_code + '/' + trx_ctrl_num
		   FROM #gldetail
			
	  	   --IF @@error != 0 
				--RETURN -1
	
	   END
	ELSE IF @gl_desc_def = 3
	   BEGIN
		   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 643, 5 ) + ' -- MSG: ' + 'Get the item_code'
		   UPDATE #gldetail
		   SET gl_desc = SUBSTRING(#gldetail.vendor_code + '/' + b.item_code,1,40)
		   FROM #gldetail
			INNER JOIN #apvocdt_work b ON #gldetail.trx_ctrl_num = b.trx_ctrl_num AND #gldetail.sequence_id = b.sequence_id
		   WHERE #gldetail.sequence_id > 0
		 	
	  	   --IF @@error != 0 
				--RETURN -1
	
	   END
	ELSE IF @gl_desc_def = 4
	   BEGIN
		   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 656, 5 ) + ' -- MSG: ' + 'Get the item description'
		   UPDATE #gldetail
		   SET gl_desc = SUBSTRING(#gldetail.vendor_code + '/' + b.line_desc,1,40)
		   FROM #gldetail
			INNER JOIN #apvocdt_work b ON #gldetail.trx_ctrl_num = b.trx_ctrl_num AND #gldetail.sequence_id = b.sequence_id
		   WHERE #gldetail.sequence_id > 0
		   	
	  	  -- IF @@error != 0 
				--RETURN -1
	
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
		(	journal_ctrl_num ,	rec_company_code,	account_code,	description,	document_1,
			document_2,		balance,		reference_code,	nat_balance,	nat_cur_code,
			rate,			trx_type,		seq_ref_id,	balance_oper,	
			rate_oper,		rate_type_home,		rate_type_oper,		org_id
		)
		SELECT 	@journal_ctrl_num,	rec_company_code,	account_code,	gl_desc,	doc_ctrl_num,
			trx_ctrl_num,		(SIGN(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision)),
									reference_code,	amount,		nat_cur_code,
			rate_home,		4091,		sequence_id,	(SIGN(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)),
			rate_oper,		rate_type_home,		rate_type_oper,	org_id
		FROM #gldetail
	

	UPDATE accrualsdet SET accrualsdet.journal_ctrl_num = #gldist.journal_ctrl_num
	FROM accrualsdet
		INNER JOIN #gldist ON(accrualsdet.trx_ctrl_num = #gldist.document_2)
		INNER JOIN accrualshdr ON(accrualsdet.accrual_number = accrualshdr.accrual_number) 
		WHERE accrualshdr.period_end_date = @date_applied
	--WHERE -- accrualsdet.trans_type = 1
	--AND 
	--accrualsdet.journal_ctrl_num = ''
		
	

	EXEC @result = gltrxcdf_sp 4000, @debug_level
	
	IF @result <> 0
	 	RETURN -1
	
	
	
	EXEC @result = gltrxvfy_sp	@journal_ctrl_num,
								@debug_level
	
	IF (@result != 0)
		--RETURN -11
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	IF @@rowcount = 0
	   BEGIN
			--DROP TABLE #gldetail
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 714, 5 ) + ' -- EXIT: '
			--RETURN 0
	   END
	
	
	
	
	
	
	
	
	
	
	
	SELECT @next_period = 0
	
	SELECT  @next_period = MIN( period_start_date )
	FROM    glprd
	WHERE   period_start_date > @date_applied
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 735, 5 ) + ' -- MSG: ' + 'Create accrual Journal header record'
		SELECT @accrual_journal_ctrl_num = NULL
				
		 
		

























	
	--IF @result <> 0
	 	--RETURN -1
	
	
	
	
	













































	 	--RETURN -1
	
	
	
		
	
	
	
	--IF (@result != 0)
		--RETURN -11

	SELECT @journal_ctrl_num = '' --GGR

	DROP TABLE #gldetail
	DROP TABLE #gldist	
	DROP TABLE #amttaxincl
	
END	

	
	--DROP TABLE #gldetail
	--DROP TABLE #gldist

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 833, 5 ) + ' -- EXIT: '
RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[APVOProcessGLEntries2_sp] TO [public]
GO
