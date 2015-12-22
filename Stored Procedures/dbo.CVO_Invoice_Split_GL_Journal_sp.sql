SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Invoice_Split_GL_Journal_sp] @trx_ctrl_num	varchar(16),
												@date_applied	int,
												@date_entered	int,
												@user_id		int,
												@org_id			varchar(30)
AS
BEGIN
	-- DECLARATIONS
	DECLARE	@clearing_acct		varchar(32),
			@seg_1				varchar(32),
			@seg_2				varchar(32),
			@seg_3				varchar(32),
			@seg_4				varchar(32),
			@amount				decimal(20,8),
			@journal_ctrl_num	varchar(16),
			@company_code		varchar(8),
			@company_id			int,
			@home_currency		varchar(8),
			@oper_currency		varchar(8),
			@doc_ctrl_num		varchar(16),
			@nat_cur_code		varchar(8),
			@rate_type_home		varchar(8),
			@rate_type_oper		varchar(8),
			@rate_home			decimal(20,8),
			@rate_oper			decimal(20,8),
			@next_seq			int

	-- Working table
	CREATE TABLE #jrnl_detail (
		sequence_id		int identity(1,1),
		account_code	varchar(32),
		amount			decimal(20,8),
		seg1_code		varchar(32),
		seg2_code		varchar(32),
		seg3_code		varchar(32),
		seg4_code		varchar(32))

	-- Get the clearing acct
	SELECT	@clearing_acct = value_str
	FROM	dbo.config (NOLOCK)
	WHERE	flag = 'INSTALL CLEAR ACCT'

	-- Get the company code
	SELECT	@company_code = company_code,
			@home_currency = home_currency,
			@oper_currency = oper_currency,
			@company_id = company_id
	FROM	dbo.glco (NOLOCK)

	-- Get the segments
	SELECT	@seg_1 = seg1_code,
			@seg_2 = seg2_code,
			@seg_3 = seg3_code,
			@seg_4 = seg4_code
	FROM	dbo.glchart (NOLOCK)
	WHERE	account_code = @clearing_acct

	-- Get the invoice value
	SELECT	-- v1.6 @amount = amt_net, -- v1.6 - amt_freight - amt_tax, -- v1.4 amt_gross,
			@doc_ctrl_num = doc_ctrl_num,
			@nat_cur_code = nat_cur_code,
			@rate_type_home	= rate_type_home,
			@rate_type_oper = rate_type_oper,
			@rate_home = rate_home,
			@rate_oper = rate_oper
	FROM	#arinpchg
	WHERE	trx_ctrl_num = @trx_ctrl_num

	-- Get the details
	INSERT	#jrnl_detail (account_code, amount, seg1_code, seg2_code, seg3_code, seg4_code)
	SELECT	a.gl_rev_acct, 
			ROUND(SUM(a.unit_price * a.qty_shipped),2), -- v1.6
-- v1.1			ROUND(SUM(a.unit_price * a.qty_shipped),2),
-- v1.6			SUM(ROUND(a.extended_price,2)), -- * a.qty_shipped,2)), -- v1.1 -- v1.3
			b.seg1_code,
			b.seg2_code,
			b.seg3_code,
			b.seg4_code
	FROM	#arinpcdt a
	JOIN	dbo.glchart b (NOLOCK)
	ON		a.gl_rev_acct = b.account_code
	WHERE	a.trx_ctrl_num = @trx_ctrl_num
	AND		a.unit_price > 0.00
	GROUP BY a.gl_rev_acct,
			 b.seg1_code,
			 b.seg2_code,
			 b.seg3_code,
			 b.seg4_code
	
	-- v1.6 Start
	SELECT	@amount = SUM(amount)
	FROM	#jrnl_detail
	-- v1. 6 End

	IF @@ERROR <> 0
		RETURN -1

	IF NOT EXISTS (SELECT 1 FROM #jrnl_detail) -- v1.2
		RETURN 0

	-- Get the sequence_id of the clearing account line
	SELECT	@next_seq = MAX(sequence_id) + 1
	FROM	#jrnl_detail

	IF @@ERROR <> 0
		RETURN -1

	-- Generate new journal number
	EXEC dbo.glnxttrx_sp @journal_ctrl_num OUTPUT

	IF @@ERROR <> 0
		RETURN -1
	
	-- Create the journal header record
	INSERT	dbo.gltrx (journal_type, journal_ctrl_num, journal_description, date_entered, date_applied, 
				recurring_flag, repeating_flag, reversing_flag, hold_flag, posted_flag, date_posted, 
				source_batch_code, batch_code, type_flag, intercompany_flag, company_code, app_id, 
				home_cur_code, document_1, trx_type, user_id, source_company_code, process_group_num, 
				oper_cur_code, org_id, interbranch_flag)
	SELECT	'AR', @journal_ctrl_num, 'Installment Invoice', @date_entered, @date_applied, 
			0, 0, 0, 0, 0, 0, '', '', 0, 0, @company_code, 6000, 
			@home_currency, '', 111, @user_id, '', '', 	@oper_currency, @org_id, 0

	IF @@ERROR <> 0
		RETURN -1

	-- Create the journal detail record based on the sales orders
	INSERT	dbo.gltrxdet (journal_ctrl_num, sequence_id, rec_company_code, company_id, account_code, 
				description, document_1, document_2, reference_code, balance, nat_balance, nat_cur_code, 
				rate, posted_flag, date_posted, trx_type, offset_flag, seg1_code, seg2_code, seg3_code, 
				seg4_code, seq_ref_id, balance_oper, rate_oper, rate_type_home, rate_type_oper, org_id)
	SELECT	@journal_ctrl_num, sequence_id, @company_code, @company_id, account_code, 'Installment Invoice',
			@doc_ctrl_num, @journal_ctrl_num, '', ROUND(((amount * @rate_home)  * -1),2), ROUND((amount * -1),2), 
			@nat_cur_code, @rate_home, 0, 0, 111, 0, seg1_code, seg2_code, seg3_code, seg4_code, 0, 
			ROUND(((amount * @rate_oper)  * -1),2), @rate_oper, @rate_type_home, @rate_type_oper, @org_id
	FROM	#jrnl_detail

	IF @@ERROR <> 0
		RETURN -1

	-- Create the journal detail record based on the clearing account
	INSERT	dbo.gltrxdet (journal_ctrl_num, sequence_id, rec_company_code, company_id, account_code, 
				description, document_1, document_2, reference_code, balance, nat_balance, nat_cur_code, 
				rate, posted_flag, date_posted, trx_type, offset_flag, seg1_code, seg2_code, seg3_code, 
				seg4_code, seq_ref_id, balance_oper, rate_oper, rate_type_home, rate_type_oper, org_id)
	SELECT	@journal_ctrl_num, @next_seq, @company_code, @company_id, @clearing_acct, 'Installment Invoice',
			@doc_ctrl_num, @journal_ctrl_num, '', ROUND((@amount * @rate_home),2), ROUND(@amount,2), 
			@nat_cur_code, @rate_home, 0, 0, 111, 0, @seg_1, @seg_2, @seg_3, @seg_4, 0, 
			ROUND((@amount * @rate_oper),2), @rate_oper, @rate_type_home, @rate_type_oper, @org_id

	IF @@ERROR <> 0
		RETURN -1

	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[CVO_Invoice_Split_GL_Journal_sp] TO [public]
GO
