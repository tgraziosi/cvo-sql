
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[APVOProcessGLEntries_sp]	@process_group_num varchar(16),  
											@date_applied int,  
											@batch_ctrl_num varchar(16),  
											@user_id int,  
											@journal_ctrl_num varchar(16) OUTPUT,  
											@debug_level smallint = 0  
  
AS  
BEGIN  
	DECLARE	@journal_type varchar(8),    
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
			@org_id  varchar(30),   
			@interbranch_flag  int,              
			@count_org_id  int,  
			@count_acc int    
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 104, 5 ) + ' -- ENTRY: '  
  
	SELECT  @credit_invoice_flag  = credit_invoice_flag,  
			@gl_desc_def   = gl_desc_def  
	FROM	apco  
  
	SELECT  @journal_type = journal_type  
	FROM    glappid  
	WHERE   app_id = 4000  
  
	SELECT  @company_code = a.company_code,   
			@home_curr_code = a.home_currency,  
			@oper_curr_code = a.oper_currency,  
			@home_precision = b.curr_precision,  
			@oper_precision = c.curr_precision,  
			@interbranch_flag = ib_flag  
	FROM	glco a  
	INNER JOIN glcurr_vw b on a.home_currency = b.currency_code  
	INNER JOIN glcurr_vw c on a.oper_currency = c.currency_code  
    
	EXEC appdate_sp @current_date OUTPUT  
  
	SELECT  @org_id = org_id   
	FROM	#apvochg_work  
	WHERE	batch_code = @batch_ctrl_num  
  
	IF @interbranch_flag = 1  
	BEGIN  
		SELECT	@count_org_id = COUNT(d.org_id)  
		FROM	#apvochg_work h  
		INNER JOIN #apvocdt_work d ON h.trx_ctrl_num = d.trx_ctrl_num AND h.org_id  != d.org_id  
		WHERE	h.intercompany_flag =0  
     
		IF @count_org_id = 0  
			SELECT  @interbranch_flag = 0  
	END  
    
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 156, 5 ) + ' -- MSG: ' + 'Create Journal header record'  
  
	EXEC  @result = gltrxcrh_sp	@process_group_num, -1, 4000, 2, @journal_type, @journal_ctrl_num OUTPUT, 'From Voucher Posting.', @current_date,  
									@date_applied, 0, 0, 0, @batch_ctrl_num, 0, @company_code, @company_code, @home_curr_code, '', 4091, @user_id,  
									0, @oper_curr_code, @debug_level, @org_id, @interbranch_flag    
	IF @result <> 0  
		RETURN -1    
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 189, 5 ) + ' -- MSG: ' + 'Create #gldetail table'  

	CREATE TABLE #gldetail (  
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
		org_id varchar(30) NULL)  

	IF @@error != 0   
		RETURN -1  
  
	CREATE INDEX TEMP_gldetail_ind0 ON #gldetail (trx_ctrl_num)  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 218, 5 ) + ' -- MSG: ' + 'Debit the expense accounts'  

	INSERT	#gldetail  
	SELECT  a.gl_exp_acct,  
			b.vendor_code,  
			'',  
			a.rec_company_code,  
			b.doc_ctrl_num,  
			b.trx_ctrl_num,  
			a.reference_code,  
			a.amt_extended - a.amt_discount + a.amt_freight + a.amt_tax + a.amt_misc,  
			b.nat_cur_code,  
			b.rate_type_home,  
			b.rate_type_oper,  
			b.rate_home,  
			b.rate_oper,  
			a.sequence_id,  
			0,  
			a.org_id  
	FROM	#apvocdt_work a  
	INNER JOIN #apvochg_work b ON a.trx_ctrl_num = b.trx_ctrl_num  
  
	--- RMV   
	declare @ib_offset smallint, @ib_seg smallint, @ib_length smallint, @segment_length smallint, @ib_flag smallint  
	
	select	@ib_offset = ib_offset, @ib_seg = ib_segment, @ib_length = ib_length, @ib_flag = ib_flag  
	from	glco  
  
	--select @segment_length = ISNULL(sum(length),0) from glaccdef where acct_level < @ib_seg   --- AC update to correct use of length  
	--select @segment_length = ISNULL(max(length),0) from glaccdef where acct_level < @ib_seg      --- AC update to correct use of length  
  
	-- scr 38330  
	select @segment_length = ISNULL(start_col - 1, 0 ) from glaccdef where acct_level = @ib_seg     
	-- end 38330  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 245, 5 ) + ' -- MSG: ' + 'Credit the amount discount'  

	INSERT	#gldetail  
	SELECT  --dbo.IBAcctMask_fn(b.disc_given_acct_code,a.org_id),   
			CASE WHEN @ib_flag = 0 THEN b.disc_given_acct_code  
				ELSE STUFF(b.disc_given_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,   
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
	FROM	#apvochg_work a   
	INNER JOIN apaccts b ON a.posting_code = b.posting_code  
	inner join Organization c ON a.org_id = c.organization_id  
	WHERE	(ABS((a.glamt_discount)-(0.0)) > 0.0000001)  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 274, 5 ) + ' -- MSG: ' + 'debit the amount misc'  

	INSERT	#gldetail  
	SELECT  --dbo.IBAcctMask_fn(b.misc_chg_acct_code,a.org_id),   
			CASE WHEN @ib_flag = 0 THEN b.misc_chg_acct_code  
				ELSE STUFF(b.misc_chg_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,   
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
	FROM	#apvochg_work a  
	INNER JOIN apaccts b ON a.posting_code = b.posting_code  
	inner join Organization c ON a.org_id = c.organization_id  
	WHERE	(ABS((a.glamt_misc)-(0.0)) > 0.0000001)   
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 312, 5 ) + ' -- MSG: ' + 'Debit the amount tax'  

	INSERT	#gldetail  
	SELECT  --dbo.IBAcctMask_fn(b.sales_tax_acct_code,a.org_id),  
			CASE WHEN @ib_flag = 0 THEN b.sales_tax_acct_code  
				ELSE STUFF(b.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,   
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
	WHERE	a.amt_tax != a.glamt_tax     
	AND		((a.glamt_tax) > (0.0) + 0.0000001)  
  
	INSERT	#gldetail  
	SELECT  DISTINCT CASE WHEN RTRIM(LTRIM(d.sales_tax_acct_code)) = '' THEN   
						CASE WHEN @ib_flag = 0 THEN e.sales_tax_acct_code  
						ELSE STUFF( e.sales_tax_acct_code,@ib_offset + @segment_length ,@ib_length, f.branch_account_number) END  
					ELSE CASE WHEN @ib_flag = 0 THEN d.sales_tax_acct_code  
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
	FROM	#apvochg_work b  
	INNER JOIN apinptax c ON b.trx_ctrl_num = c.trx_ctrl_num AND b.trx_type = c.trx_type  
	INNER JOIN artxtype d ON c.tax_type_code = d.tax_type_code  
	INNER JOIN apaccts e ON b.posting_code = e.posting_code  
	INNER JOIN Organization f ON b.org_id = f.organization_id    
	WHERE	b.amt_tax = b.glamt_tax      
	AND		c.amt_final_tax <> 0.0  
	AND		d.recoverable_flag = 1  
	AND		d.tax_based_type <> 2  
  
	INSERT	#gldetail  
	SELECT  DISTINCT CASE WHEN @ib_flag = 0 THEN e.freight_acct_code  
						ELSE STUFF(e.freight_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,   
			b.vendor_code,  
			'non-recoverable tax',  
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
	FROM	#apvochg_work b  
	INNER JOIN apaccts e ON b.posting_code = e.posting_code  
	INNER JOIN Organization c ON b.org_id = c.organization_id  
	WHERE	b.tax_freight_no_recoverable <> 0.0    
  
	INSERT	#gldetail  
	SELECT  DISTINCT CASE WHEN @ib_flag = 0 THEN d.sales_tax_acct_code   
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
	FROM	#apvochg_work b  
	INNER JOIN apinptax c ON b.trx_ctrl_num = c.trx_ctrl_num AND b.trx_type = c.trx_type  
	INNER JOIN artxtype d ON c.tax_type_code = d.tax_type_code  
	INNER JOIN apaccts e ON b.posting_code = e.posting_code  
	INNER JOIN Organization f ON b.org_id = f.organization_id  
	WHERE	b.amt_tax = b.glamt_tax      
	AND		c.amt_final_tax <> 0.0  
	AND		d.recoverable_flag = 1  
	AND		d.tax_based_type = 2  
  
	--  
	-- Summarize non-recoverable taxes by transaction and account_code  
	--  
	DECLARE @sumtax TABLE(  
		trx_ctrl_num  varchar(16),  
		trx_type  integer,  
		amt_final_tax  float,  
		account_code  varchar(32),  
		rec_company_code varchar(8),  
		org_id  varchar(30) NULL,  
		reference_code  varchar(32) NULL)  
  
	INSERT	@sumtax  
	SELECT	t.trx_ctrl_num, t.trx_type, amt_final_tax=SUM(t.amt_final_tax), t.account_code,  d.rec_company_code, d.org_id, d.reference_code       
	FROM	#apvotaxdtl_work t  
	INNER JOIN #apvochg_work h ON t.trx_ctrl_num = h.trx_ctrl_num AND t.trx_type = h.trx_type  
	INNER JOIN #apvocdt_work d ON t.trx_ctrl_num = d.trx_ctrl_num AND t.trx_type = d.trx_type AND t.detail_sequence_id =  d.sequence_id  
	WHERE	t.recoverable_flag = 0  
	GROUP BY t.trx_ctrl_num, t.trx_type, t.account_code, d.rec_company_code, d.org_id, d.reference_code       
  
	--  
	-- Create GL Details for non-recoverable taxes  
	--  
	INSERT	#gldetail  
	SELECT  DISTINCT t.account_code,  
			b.vendor_code,  
			'non-recoverable tax',  
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
	FROM	#apvochg_work b  
	INNER JOIN @sumtax t ON b.trx_ctrl_num = t.trx_ctrl_num AND b.trx_type = t.trx_type  
	WHERE	t.amt_final_tax <> 0.0  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 494, 5 ) + ' -- MSG: ' + 'hit the tax included rounding account'  
	SELECT	a.trx_ctrl_num,  
			calc_tax = SUM(b.calc_tax * c.tax_included_flag)  
	INTO	#amttaxincl  
	FROM	#apvochg_work a  
	INNER JOIN #apvocdt_work b ON a.trx_ctrl_num = b.trx_ctrl_num  
	INNER JOIN aptax c ON b.tax_code = c.tax_code  
	GROUP BY a.trx_ctrl_num  
  
	INSERT	#gldetail  
	SELECT  CASE WHEN @ib_flag = 0 THEN b.tax_rounding_acct  
				ELSE STUFF(b.tax_rounding_acct,@ib_offset + @segment_length ,@ib_length, d.branch_account_number) END,   
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
	WHERE	(ABS((c.calc_tax)-(a.amt_tax_included)) > 0.0000001)  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 529, 5 ) + ' -- MSG: ' + 'Debit the amount freight'  

	INSERT	#gldetail  
	SELECT  CASE WHEN @ib_flag = 0 THEN b.freight_acct_code  
				ELSE STUFF(b.freight_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,   
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
	FROM	#apvochg_work a  
	INNER JOIN apaccts b ON a.posting_code = b.posting_code  
	INNER JOIN Organization c ON a.org_id = c.organization_id  
	AND		(ABS((a.glamt_freight)-(0.0)) > 0.0000001)  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 564, 5 ) + ' -- MSG: ' + 'credit the ap-acct code'  
	INSERT	#gldetail  
	SELECT  CASE WHEN @ib_flag = 0 THEN b.ap_acct_code  
				ELSE STUFF(b.ap_acct_code,@ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,   
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
	FROM	#apvochg_work a  
	INNER JOIN apaccts b ON a.posting_code = b.posting_code  
	INNER JOIN Organization c ON a.org_id = c.organization_id  
	WHERE	(((a.amt_net) > (0.0) + 0.0000001) OR a.amt_net = 0.0 )  
	AND		@credit_invoice_flag = 0   
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 593, 5 ) + ' -- MSG: ' + 'credit the ap-acct code'  
	INSERT	#gldetail  
	SELECT  CASE WHEN @ib_flag = 0 THEN b.ap_acct_code  
				ELSE STUFF(b.ap_acct_code, @ib_offset + @segment_length ,@ib_length, c.branch_account_number) END,   
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
	FROM	#apvochg_work a  
	INNER JOIN apaccts b ON a.posting_code = b.posting_code  
	INNER JOIN Organization c ON a.org_id = c.organization_id  
	WHERE	@credit_invoice_flag = 1    
	  
	IF @gl_desc_def = 1  
	BEGIN  
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 621, 5 ) + ' -- MSG: ' + 'Get the vendor name'  
    
		UPDATE	#gldetail  
		SET		gl_desc = b.vendor_name  
		FROM	#gldetail  
		INNER JOIN apvend b ON #gldetail.vendor_code = b.vendor_code  
  
		IF @@error != 0   
			RETURN -1  
  
	END  
	ELSE IF @gl_desc_def = 2  
	BEGIN  
		UPDATE	#gldetail  
		SET		gl_desc = vendor_code + '/' + trx_ctrl_num  
		FROM	#gldetail  
 
		IF @@error != 0   
			RETURN -1  
  
	END  
	ELSE IF @gl_desc_def = 3  
	BEGIN  
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 643, 5 ) + ' -- MSG: ' + 'Get the item_code'  

		UPDATE	#gldetail  
		SET		gl_desc = SUBSTRING(#gldetail.vendor_code + '/' + b.item_code,1,40)  
		FROM	#gldetail  
		INNER JOIN #apvocdt_work b ON #gldetail.trx_ctrl_num = b.trx_ctrl_num AND #gldetail.sequence_id = b.sequence_id  
		WHERE	#gldetail.sequence_id > 0  
  
		IF @@error != 0   
			RETURN -1  
  
	END  
	ELSE IF @gl_desc_def = 4  
	BEGIN  
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 656, 5 ) + ' -- MSG: ' + 'Get the item description'  
    
		UPDATE	#gldetail  
		SET		gl_desc = SUBSTRING(IsNull(v.vendor_short_name,'') + '/' + b.line_desc,1,40)
		FROM	#gldetail  
		INNER JOIN #apvocdt_work b ON #gldetail.trx_ctrl_num = b.trx_ctrl_num AND #gldetail.sequence_id = b.sequence_id  
		LEFT OUTER JOIN apvend v ON #gldetail.vendor_code = v.vendor_code     
		WHERE	#gldetail.sequence_id > 0  
  
		IF @@error != 0   
			RETURN -1  
  
	END  
  
	CREATE TABLE #gldist (  
		journal_ctrl_num varchar(16),  
		rec_company_code varchar(8),   
		account_code  varchar(32),   
		description  varchar(40), 
		document_1  varchar(16),    
		document_2  varchar(16),    
		reference_code  varchar(32),   
		balance   float,    
		nat_balance  float,    
		nat_cur_code  varchar(8),   
		rate   float,    
		trx_type  smallint,  
		seq_ref_id  int,    
		balance_oper            float NULL,  
		rate_oper               float NULL,  
		rate_type_home          varchar(8) NULL,  
		rate_type_oper          varchar(8) NULL,  
		org_id  varchar(30) NULL)  
    
	INSERT	#gldist (journal_ctrl_num , rec_company_code, account_code, description, document_1,  
					document_2,  balance,  reference_code, nat_balance, nat_cur_code,  
					rate,   trx_type,  seq_ref_id, balance_oper,   
					rate_oper,  rate_type_home,  rate_type_oper,  org_id)  
	SELECT  @journal_ctrl_num, rec_company_code, account_code, gl_desc, doc_ctrl_num,  
			trx_ctrl_num,  (SIGN(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * 
				SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + 
				SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision)),  
			reference_code, amount,  nat_cur_code,  
			rate_home,  4091,  sequence_id, (SIGN(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - 
				ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + 
				(SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)),  
			rate_oper,  rate_type_home,  rate_type_oper, org_id  
	FROM	#gldetail  
  
	EXEC @result = gltrxcdf_sp 4000, @debug_level  
  
	IF @result <> 0  
		RETURN -1  
  
	EXEC @result = gltrxvfy_sp @journal_ctrl_num, @debug_level  
  
	IF (@result != 0)  
		RETURN -11  
  
	SELECT	@count_acc = COUNT(1)  
	FROM	#gldetail a  
	INNER JOIN #apvochg_work b ON a.trx_ctrl_num = b.trx_ctrl_num  
	WHERE	b.accrual_flag = 1   
  
	IF @count_acc = 0  
    BEGIN  
		DROP TABLE #gldetail  
   
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 714, 5 ) + ' -- EXIT: '  
	
		RETURN 0  
    END  

	SELECT @next_period = 0  
  
	SELECT  @next_period = MIN( period_start_date )  
	FROM    glprd  
	WHERE   period_start_date > @date_applied  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 735, 5 ) + ' -- MSG: ' + 'Create accrual Journal header record'  
 
	SELECT @accrual_journal_ctrl_num = NULL  
  
	EXEC  @result = gltrxcrh_sp @process_group_num, -1, 4000, 2, @journal_type, @accrual_journal_ctrl_num OUTPUT, 'To offset accrual vouchers.', @current_date,  
								@next_period, 0, 0, 0, @batch_ctrl_num, 0, @company_code, @company_code, @home_curr_code, '', 4091, @user_id, 0, @oper_curr_code,  
								@debug_level, @org_id, @interbranch_flag   
  
	IF @result <> 0  
		RETURN -1  
  
	INSERT #gldist (journal_ctrl_num, rec_company_code, account_code, description, document_1, document_2, balance, reference_code, nat_balance, nat_cur_code,  
					rate, trx_type, seq_ref_id, balance_oper, rate_oper, rate_type_home, rate_type_oper, org_id)  
	SELECT	@accrual_journal_ctrl_num,  
			a.rec_company_code,  
			a.account_code,  
			a.gl_desc,  
			a.doc_ctrl_num,  
			a.trx_ctrl_num,  
			(SIGN(-a.amount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * 
				SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(-a.amount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + 
				SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision)),  
			a.reference_code,  
			-a.amount,  
			a.nat_cur_code,  
			a.rate_home,  
			4091,  
			a.sequence_id,  
			(SIGN(-a.amount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * 
				SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(-a.amount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + 
				SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision)),  
			a.rate_oper,  
			a.rate_type_home,  
			a.rate_type_oper,  
			a.org_id  
	FROM	#gldetail a  
	INNER JOIN #apvochg_work b ON a.trx_ctrl_num = b.trx_ctrl_num  
	WHERE	b.accrual_flag = 1  
  
	EXEC @result = gltrxcdf_sp 4000, @debug_level   

	IF @result <> 0  
		RETURN -1  
  
	EXEC @result = gltrxvfy_sp @accrual_journal_ctrl_num, @debug_level  
  
	IF (@result != 0)  
		RETURN -11  

	DROP TABLE #gldetail  
	DROP TABLE #gldist  
  
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopgle.cpp' + ', line ' + STR( 833, 5 ) + ' -- EXIT: '  

	RETURN 0  
END
GO


GRANT EXECUTE ON  [dbo].[APVOProcessGLEntries_sp] TO [public]
GO
