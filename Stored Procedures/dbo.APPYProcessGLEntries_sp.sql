SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APPYProcessGLEntries_sp]    @process_group_num varchar(16),
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
				@vendor_name varchar(40),
				@line_desc varchar(40),
				@gl_desc_def smallint,
				@result int,
				@amount float,
				@nat_cur_code varchar(8),
				@rate_type_home varchar(8),
				@rate_type_oper	varchar(8),
				@rate_home float,
				@rate_oper float,
				@sq_id int,
				@home_precision smallint,
				@oper_precision smallint,
				@home_amount float,
				@oper_amount float,
				@oper_curr_code varchar(8),
                                @org_id	varchar(30),                        	
                                @interbranch_flag	int,             	
				@count_org_id		int
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 92, 5 ) + ' -- ENTRY: '








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
FROM	#appypyt_work
WHERE	batch_code = @batch_ctrl_num



IF @interbranch_flag = 1
BEGIN

	SELECT 	@count_org_id = COUNT(d.org_id)
	FROM	#appypyt_work h,  #appypdt_work d
	WHERE	h.trx_ctrl_num 	= d.trx_ctrl_num
	AND	h.org_id 	!= d.org_id

	IF @count_org_id = 0
		SELECT 	@interbranch_flag = 0

END








IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 147, 5 ) + ' -- MSG: ' + 'Create Journal header record'

	EXEC 	@result = gltrxcrh_sp 
			@process_group_num,
			-1,
			4000, 
			2,
			@journal_type,
			@journal_ctrl_num OUTPUT,
			'From Cash Disb. Posting.',
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
			'', 
			4111,
			@user_id,
			0,			  
			@oper_curr_code,
                        0,
			@org_id,		
			@interbranch_flag	        



IF @result <> 0
 	RETURN -1


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 182, 5 ) + ' -- MSG: ' + 'Create #gldetail table'
CREATE TABLE #gldetail
(
 account_code varchar(32),
 vendor_code varchar(12),
 gl_desc varchar(40),
 doc_ctrl_num varchar(16),
 trx_ctrl_num varchar(16),
 amount float,
 amount_home float,
 amount_oper float,
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






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 210, 5 ) + ' -- MSG: ' + 'Debit the A/P accounts'
INSERT #gldetail
SELECT 	dbo.IBAcctMask_fn(a.ap_acct_code,b.org_id),
		c.vendor_code,
		'',
		c.doc_ctrl_num,
		c.trx_ctrl_num,
		b.vo_amt_applied + b.vo_amt_disc_taken,
		(SIGN((b.vo_amt_applied + b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) * ROUND(ABS((b.vo_amt_applied + b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) + 0.0000001, @home_precision)),
		(SIGN((b.vo_amt_applied + b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) * ROUND(ABS((b.vo_amt_applied + b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
		b.nat_cur_code,
		d.rate_type_home,
		d.rate_type_oper,
		d.rate_home,
		d.rate_oper,
		b.sequence_id,
		0,
                b.org_id        
FROM apaccts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
WHERE a.posting_code = d.posting_code
AND b.apply_to_num = d.trx_ctrl_num
AND b.trx_ctrl_num = c.trx_ctrl_num

IF @@error != 0 
	RETURN -1

	   




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 241, 5 ) + ' -- MSG: ' + 'Credit the discount taken accounts'
INSERT #gldetail
SELECT 	dbo.IBAcctMask_fn(a.disc_taken_acct_code,b.org_id),
		c.vendor_code,
		'',
		c.doc_ctrl_num,
		c.trx_ctrl_num,
		-b.vo_amt_disc_taken,
		(SIGN((-b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) * ROUND(ABS((-b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) + 0.0000001, @home_precision)),
		(SIGN((-b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) * ROUND(ABS((-b.vo_amt_disc_taken) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
		b.nat_cur_code,
		d.rate_type_home,
		d.rate_type_oper,
		d.rate_home,
		d.rate_oper,
		b.sequence_id,
		0,
		b.org_id        
FROM apaccts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
WHERE a.posting_code = d.posting_code
AND b.apply_to_num = d.trx_ctrl_num
AND b.trx_ctrl_num = c.trx_ctrl_num
AND ((b.vo_amt_disc_taken) > (0.0) + 0.0000001)

IF @@error != 0 
	RETURN -1

  



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 272, 5 ) + ' -- MSG: ' + 'Credit the cash accounts'
INSERT #gldetail
SELECT 	cash_acct_code,
		vendor_code,
		'',
		doc_ctrl_num,
		trx_ctrl_num,
		-amt_payment,
		(SIGN((-amt_payment) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS((-amt_payment) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision)),
		(SIGN((-amt_payment) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS((-amt_payment) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)),
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		0,
		0,
                org_id        
FROM #appypyt_work 
WHERE payment_type = 1

IF @@error != 0 
	RETURN -1


   



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 301, 5 ) + ' -- MSG: ' + 'Debit the on-acct accounts'
INSERT #gldetail
SELECT 	dbo.IBAcctMask_fn(b.on_acct_code,a.org_id),
		a.vendor_code,
		'',
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		a.amt_on_acct,
		(SIGN((a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS((a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision)),
		(SIGN((a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS((a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #appypyt_work a, appymeth b
WHERE a.payment_code = b.payment_code
AND   a.payment_type = 1
AND	  ((a.amt_on_acct) > (0.0) + 0.0000001)
  
IF @@error != 0 
	RETURN -1






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 332, 5 ) + ' -- MSG: ' + 'Credit the on_acct accounts'
INSERT #gldetail
SELECT 	dbo.IBAcctMask_fn(b.on_acct_code,a.org_id),
		a.vendor_code,
		'',
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		-a.amt_payment + a.amt_on_acct,
		(SIGN((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision)),
		(SIGN((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #appypyt_work a, appymeth b
WHERE a.payment_code = b.payment_code
AND   a.payment_type = 2

IF @@error != 0 
	RETURN -1






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 362, 5 ) + ' -- MSG: ' + 'Credit the DM on_acct Accounts'
INSERT #gldetail
SELECT 	dbo.IBAcctMask_fn(b.dm_on_acct_code,a.org_id),
		a.vendor_code,
		'',
		a.doc_ctrl_num,
		a.trx_ctrl_num,
		-a.amt_payment + a.amt_on_acct,
		(SIGN((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision)),
		(SIGN((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS((-a.amt_payment + a.amt_on_acct) * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
		a.nat_cur_code,
		a.rate_type_home,
		a.rate_type_oper,
		a.rate_home,
		a.rate_oper,
		0,
		0,
                a.org_id        
FROM #appypyt_work a, apaccts b, #appytrxp_work c
WHERE a.doc_ctrl_num = c.doc_ctrl_num
AND   c.posting_code = b.posting_code
AND   a.payment_type = 3
  
IF @@error != 0 
	RETURN -1


CREATE TABLE #g_l_accts
(
 trx_ctrl_num varchar(16),
 nat_cur_code varchar(8),
 ap_acct_code varchar(32),
 gain_acct varchar(32),
 loss_acct varchar(32),
 org_id varchar(30) NULL        
)

INSERT #g_l_accts
SELECT DISTINCT a.trx_ctrl_num, b.nat_cur_code, dbo.IBAcctMask_fn(d.ap_acct_code,c.org_id), '', '' ,
        c.org_id                
FROM #appytrxv_work a, #appypdt_work b, #appypyt_work c, apaccts d
WHERE a.trx_ctrl_num = b.apply_to_num
AND b.trx_ctrl_num = c.trx_ctrl_num
AND a.posting_code = d.posting_code
AND (b.nat_cur_code != c.nat_cur_code
     OR (ABS((gain_home)-(0.0)) > 0.0000001)
	 OR (ABS((gain_oper)-(0.0)) > 0.0000001) )


IF @@rowcount != 0
   BEGIN


				SELECT a.currency_code, b.ap_acct_code, sequence_id = MIN(a.sequence_id)
				INTO #temp
				FROM CVO_Control..mccocdt a, #g_l_accts b
				WHERE a.company_code = @company_code
				AND b.ap_acct_code like a.acct_mask
				AND a.currency_code = b.nat_cur_code
				GROUP BY a.currency_code, b.ap_acct_code



				UPDATE #g_l_accts
				SET gain_acct = c.rea_gain_acct,
				    loss_acct = c.rea_loss_acct
				FROM #g_l_accts, #temp b, CVO_Control..mccocdt c
				WHERE #g_l_accts.nat_cur_code = b.currency_code
				AND #g_l_accts.ap_acct_code = b.ap_acct_code
				AND b.currency_code = c.currency_code
				AND b.sequence_id = c.sequence_id
				AND c.company_code = @company_code


				DROP TABLE #temp

				


				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 441, 5 ) + ' -- MSG: ' + 'credit voucher amounts to gain accounts/2nd currency'
				INSERT #gldetail
				SELECT 	dbo.IBAcctMask_fn(a.gain_acct,b.org_id) ,
						c.vendor_code,
						'',
						c.doc_ctrl_num,
						c.trx_ctrl_num,
						-b.vo_amt_applied,
						(SIGN((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) * ROUND(ABS((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) + 0.0000001, @home_precision)),
						(SIGN((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) * ROUND(ABS((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
						b.nat_cur_code,
						d.rate_type_home,
						d.rate_type_oper,
						d.rate_home,
						d.rate_oper,
						b.sequence_id,
						0,
                                                b.org_id        
				FROM #g_l_accts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
				WHERE b.apply_to_num = d.trx_ctrl_num
				AND b.trx_ctrl_num = c.trx_ctrl_num
				AND ((b.gain_home) >= (0.0) - 0.0000001)
				AND d.trx_ctrl_num = a.trx_ctrl_num
				AND c.nat_cur_code != b.nat_cur_code


				IF @@error != 0 
					RETURN -1



				


				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 475, 5 ) + ' -- MSG: ' + 'credit voucher amounts to loss accounts/2nd currency'
				INSERT #gldetail
				SELECT 	dbo.IBAcctMask_fn(a.loss_acct,b.org_id) ,
						c.vendor_code,
						'',
						c.doc_ctrl_num,
						c.trx_ctrl_num,
						-b.vo_amt_applied,
						(SIGN((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) * ROUND(ABS((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_home))*(d.rate_home) + (SIGN(ABS(SIGN(ROUND(d.rate_home,6))))/(d.rate_home + SIGN(1 - ABS(SIGN(ROUND(d.rate_home,6)))))) * SIGN(SIGN(d.rate_home) - 1) )) + 0.0000001, @home_precision)),
						(SIGN((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) * ROUND(ABS((-b.vo_amt_applied) * ( SIGN(1 + SIGN(d.rate_oper))*(d.rate_oper) + (SIGN(ABS(SIGN(ROUND(d.rate_oper,6))))/(d.rate_oper + SIGN(1 - ABS(SIGN(ROUND(d.rate_oper,6)))))) * SIGN(SIGN(d.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
						b.nat_cur_code,
						d.rate_type_home,
						d.rate_type_oper,
						d.rate_home,
						d.rate_oper,
						b.sequence_id,
						0,
                                                b.org_id        
				FROM #g_l_accts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
				WHERE b.apply_to_num = d.trx_ctrl_num
				AND b.trx_ctrl_num = c.trx_ctrl_num
				AND ((b.gain_home) < (0.0) - 0.0000001)
				AND d.trx_ctrl_num = a.trx_ctrl_num
				AND c.nat_cur_code != b.nat_cur_code


				IF @@error != 0 
					RETURN -1



				


				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 509, 5 ) + ' -- MSG: ' + 'debit payment amounts to gain accounts/2nd currency'
				INSERT #gldetail
				SELECT 	dbo.IBAcctMask_fn(a.gain_acct,b.org_id) ,
						c.vendor_code,
						'',
						c.doc_ctrl_num,
						c.trx_ctrl_num,
						b.amt_applied,
						(SIGN((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) )) * ROUND(ABS((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) )) + 0.0000001, @home_precision)),
						(SIGN((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_oper))*(c.rate_oper) + (SIGN(ABS(SIGN(ROUND(c.rate_oper,6))))/(c.rate_oper + SIGN(1 - ABS(SIGN(ROUND(c.rate_oper,6)))))) * SIGN(SIGN(c.rate_oper) - 1) )) * ROUND(ABS((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_oper))*(c.rate_oper) + (SIGN(ABS(SIGN(ROUND(c.rate_oper,6))))/(c.rate_oper + SIGN(1 - ABS(SIGN(ROUND(c.rate_oper,6)))))) * SIGN(SIGN(c.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
						c.nat_cur_code,
						c.rate_type_home,
						c.rate_type_oper,
						c.rate_home,
						c.rate_oper,
						b.sequence_id,
						0,
                                                b.org_id        
				FROM #g_l_accts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
				WHERE b.apply_to_num = d.trx_ctrl_num
				AND b.trx_ctrl_num = c.trx_ctrl_num
				AND ((b.gain_home) >= (0.0) - 0.0000001)
				AND d.trx_ctrl_num = a.trx_ctrl_num
				AND c.nat_cur_code != b.nat_cur_code


				IF @@error != 0 
					RETURN -1



				


				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 543, 5 ) + ' -- MSG: ' + 'debit payment amounts to loss accounts/2nd currency'
				INSERT #gldetail
				SELECT 	dbo.IBAcctMask_fn(a.loss_acct,b.org_id) ,
						c.vendor_code,
						'',
						c.doc_ctrl_num,
						c.trx_ctrl_num,
						b.amt_applied,
						(SIGN((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) )) * ROUND(ABS((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) )) + 0.0000001, @home_precision)),
						(SIGN((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_oper))*(c.rate_oper) + (SIGN(ABS(SIGN(ROUND(c.rate_oper,6))))/(c.rate_oper + SIGN(1 - ABS(SIGN(ROUND(c.rate_oper,6)))))) * SIGN(SIGN(c.rate_oper) - 1) )) * ROUND(ABS((b.amt_applied) * ( SIGN(1 + SIGN(c.rate_oper))*(c.rate_oper) + (SIGN(ABS(SIGN(ROUND(c.rate_oper,6))))/(c.rate_oper + SIGN(1 - ABS(SIGN(ROUND(c.rate_oper,6)))))) * SIGN(SIGN(c.rate_oper) - 1) )) + 0.0000001, @oper_precision)),
						c.nat_cur_code,
						c.rate_type_home,
						c.rate_type_oper,
						c.rate_home,
						c.rate_oper,
						b.sequence_id,
						0,
                                                b.org_id        
				FROM #g_l_accts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
				WHERE b.apply_to_num = d.trx_ctrl_num
				AND b.trx_ctrl_num = c.trx_ctrl_num
				AND ((b.gain_home) < (0.0) - 0.0000001)
				AND d.trx_ctrl_num = a.trx_ctrl_num
				AND c.nat_cur_code != b.nat_cur_code


				IF @@error != 0 
					RETURN -1


				


				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 576, 5 ) + ' -- MSG: ' + 'adjust amounts to gain accounts/1st currency'
				INSERT #gldetail
				SELECT 	dbo.IBAcctMask_fn(a.gain_acct,b.org_id),
						c.vendor_code,
						'',
						c.doc_ctrl_num,
						c.trx_ctrl_num,
						0.0,
						-b.gain_home,
						-b.gain_oper,
						b.nat_cur_code,
						d.rate_type_home,
						d.rate_type_oper,
						0.0,
						0.0,
						b.sequence_id,
						0,
                                                b.org_id        
				FROM #g_l_accts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
				WHERE b.apply_to_num = d.trx_ctrl_num
				AND b.trx_ctrl_num = c.trx_ctrl_num
				AND ((b.gain_home) >= (0.0) - 0.0000001)
				AND d.trx_ctrl_num = a.trx_ctrl_num
				AND c.nat_cur_code = b.nat_cur_code
				AND ((ABS((b.gain_home)-(0.0)) > 0.0000001) OR (ABS((b.gain_oper)-(0.0)) > 0.0000001))


				IF @@error != 0 
					RETURN -1


				


				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 610, 5 ) + ' -- MSG: ' + 'adjust amounts to loss accounts/1st currency'
				INSERT #gldetail
				SELECT 	dbo.IBAcctMask_fn(a.loss_acct,b.org_id) ,
						c.vendor_code,
						'',
						c.doc_ctrl_num,
						c.trx_ctrl_num,
						0.0,
						-b.gain_home,
						-b.gain_oper,
						b.nat_cur_code,
						d.rate_type_home,
						d.rate_type_oper,
						0.0,
						0.0,
						b.sequence_id,
						0,
                                                b.org_id        
				FROM #g_l_accts a, #appypdt_work b, #appypyt_work c, #appytrxv_work d
				WHERE b.apply_to_num = d.trx_ctrl_num
				AND b.trx_ctrl_num = c.trx_ctrl_num
				AND ((b.gain_home) < (0.0) - 0.0000001)
				AND d.trx_ctrl_num = a.trx_ctrl_num
				AND c.nat_cur_code = b.nat_cur_code


				IF @@error != 0 
					RETURN -1


	END



DROP TABLE #g_l_accts


IF @gl_desc_def = 1
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 649, 5 ) + ' -- MSG: ' + 'Get the vendor name'
	   UPDATE #gldetail
	   SET gl_desc = b.vendor_name
	   FROM #gldetail, apvend b
	   WHERE #gldetail.vendor_code = b.vendor_code

  	   IF @@error != 0 
			RETURN -1

   END
ELSE IF @gl_desc_def = 2
   BEGIN
	   UPDATE #gldetail
	   SET gl_desc = vendor_code + '/' + trx_ctrl_num
	   FROM #gldetail

  	   IF @@error != 0 
			RETURN -1

   END
ELSE IF @gl_desc_def = 3
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 671, 5 ) + ' -- MSG: ' + 'Get the item_code'
	   UPDATE #gldetail
	   SET gl_desc = vendor_code
	   FROM #gldetail 

  	   IF @@error != 0 
			RETURN -1

   END
ELSE IF @gl_desc_def = 4
   BEGIN
	   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 682, 5 ) + ' -- MSG: ' + 'Get the item description'
	   UPDATE #gldetail
	   SET gl_desc = vendor_code 
	   FROM #gldetail 

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
 @company_code,
 account_code,
 gl_desc,
 doc_ctrl_num,
 trx_ctrl_num,
 amount_home,
 '',
 amount,
 nat_cur_code,
 rate_home,
 4111,
 sequence_id,
 amount_oper,
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


DROP TABLE #gldetail

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appypgle.cpp' + ', line ' + STR( 756, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYProcessGLEntries_sp] TO [public]
GO
