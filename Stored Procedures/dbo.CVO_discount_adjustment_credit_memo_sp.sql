SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 25/06/2013 - Created
V1.1 tag 091813 - UPDATED DOC DESC to NONSALES

DECLARE @error_no		SMALLINT, @error_desc		VARCHAR(1000)

EXEC CVO_discount_adjustment_credit_memo_sp	'010125', 3.99, @error_no OUTPUT, @error_desc OUTPUT
SELECT @error_no, @error_desc

*/
CREATE PROCEDURE [dbo].[CVO_discount_adjustment_credit_memo_sp]	@customer_code	VARCHAR(8), 
															@adjustment		DECIMAL(20,8),
															@error_no		SMALLINT OUTPUT,
															@error_desc		VARCHAR(1000) OUTPUT,
															@trx_ctrl_num	VARCHAR(16) OUTPUT

AS
BEGIN

	DECLARE @num				INT,
			@date_entered		INT,
			@date_doc			INT,
			@date_applied		INT,
			@salesperson_code	VARCHAR(8),
			@territory_code		VARCHAR(8),
			@fob_code			VARCHAR(8),
			@price_code			VARCHAR(8),
			@posting_code		VARCHAR(8),
			@tax_code			VARCHAR(8),
			@amt_tax			DECIMAL(20,8),
			@user_id			SMALLINT,
			@addr1				VARCHAR(40), 
			@addr2				VARCHAR(40), 
			@addr3				VARCHAR(40), 
			@addr4				VARCHAR(40), 
			@addr5				VARCHAR(40),  
			@addr6				VARCHAR(40), 
			@city				VARCHAR(40), 
			@state				VARCHAR(40), 
			@postal_code		VARCHAR(15),
			@country_code		VARCHAR(3),
			@attention_name		VARCHAR(40),
			@attention_phone	VARCHAR(30),
			@writeoff_code		VARCHAR(8),
			@nat_cur_code		VARCHAR(8),
			@rate_type_home		VARCHAR(8), 
			@rate_type_oper		VARCHAR(8),
			@home_rate			FLOAT,   
			@oper_rate			FLOAT, 
			@error				INT,
			@account_code		VARCHAR(32),
			@err				INT 

	SET NOCOUNT ON
	
	SET @error_no = 0
	SET @error_desc = ''

	-- Get account 
	SELECT @account_code = value_str FROM config WHERE flag = 'DISC_ADJUST_ACCOUNT'

	IF NOT EXISTS (SELECT 1 FROM dbo.glchart (NOLOCK) WHERE inactive_flag = 0 AND account_code = @account_code)
	BEGIN
		RETURN -1
	END

	-- Get credit memo number
	EXEC ARGetNextControl_SP 2020, @trx_ctrl_num OUTPUT, @num OUTPUT

	-- Get dates
	SELECT @date_entered = DATEDIFF(DAY, '01/01/1900', GETDATE())+693596
	SELECT @date_doc = DATEDIFF(DAY, '01/01/1900', GETDATE())+693596
	SELECT @date_applied = period_start_date FROM glprd  WHERE period_end_date IN (SELECT period_end_date FROM arco)
	
	-- Get customer info
	SELECT 
		@addr1 = addr1, 
		@addr2 = addr2, 
		@addr3 = addr3, 
		@addr4 = addr4, 
		@addr5 = addr5,  
		@addr6 = addr6, 
		@city =city, 
		@state = [state], 
		@postal_code = postal_code, 
		@country_code = country_code, 
		@attention_name = attention_name, 
		@attention_phone = attention_phone,  
		@salesperson_code = salesperson_code, 
		@tax_code = tax_code,  
		@price_code = price_code, 
		@fob_code = fob_code,  
		@posting_code = posting_code, 
		@territory_code = territory_code, 
		@nat_cur_code = nat_cur_code,
		@rate_type_home = rate_type_home, 
		@rate_type_oper = rate_type_oper, 
		@writeoff_code = writeoff_code	
	FROM 
		dbo.arcustok_vw (NOLOCK)  
	WHERE  
		customer_code  =  @customer_code 
		AND valid_soldto_flag=1 
		AND dbo.sm_customer_vs_org_fn(customer_code,  'CVO' ) = 1

	-- Get userid
	SELECT 
		@user_id = [user_id] 
	FROM 
		dbo.smusers_vw (NOLOCK)
	WHERE 
		domain_username = suser_sname()

	-- Calculate exchange rate
	EXEC dbo.cvo_curate_sp @apply_date = @date_applied,  
						   @from_currency = @nat_cur_code,  
						   @home_type = @rate_type_home,  
						   @oper_type = @rate_type_oper,   
						   @error = @error OUTPUT,   
						   @home_rate = @home_rate OUTPUT,   
						   @oper_rate = @oper_rate OUTPUT  

	-- Calculate tax
	EXEC cvo_calculate_tax_sp @tax_code, @nat_cur_code, @customer_code , @home_rate, '001', @adjustment, @amt_tax OUTPUT, @err OUTPUT
	
	IF ISNULL(@err,0) <> 1
	BEGIN
		SET @error_desc = 'Error calculating tax - ' + CAST(@err AS VARCHAR(5))
		SET @error_no = -1
		RETURN
	END
	
	-- Begin transaction
	BEGIN TRAN

	-- Insert credit memo header
	INSERT arinpcm_vw ( 
		trx_ctrl_num, doc_ctrl_num,	doc_desc, apply_to_num,	apply_trx_type,
		order_ctrl_num,	batch_code,	trx_type, date_entered,	date_applied,
		date_doc, date_shipped, date_required, date_due, date_aging,
		customer_code, ship_to_code, salesperson_code, territory_code, comment_code,
		fob_code, freight_code, terms_code, fin_chg_code, price_code,
		dest_zone_code, posting_code, recurring_flag, recurring_code, tax_code,
		cust_po_num, total_weight, amt_gross, amt_freight, amt_tax,
		amt_tax_included, amt_discount, amt_net, amt_paid, amt_due,
		amt_cost, amt_profit, next_serial_id, printed_flag, posted_flag,
		hold_flag, hold_desc, [user_id], customer_addr1, customer_addr2,
		customer_addr3, customer_addr4, customer_addr5, customer_addr6, customer_city,
		customer_state, customer_postal_code, customer_country_code, ship_to_addr1, ship_to_addr2,
		ship_to_addr3, ship_to_addr4, ship_to_addr5, ship_to_addr6, ship_to_city,
		ship_to_state, ship_to_postal_code, ship_to_country_code, attention_name, attention_phone,
		amt_rem_rev, amt_rem_tax, date_recurring, location_code, amt_discount_taken,
		amt_write_off_given, nat_cur_code, rate_type_home, rate_type_oper, rate_home,
		rate_oper, edit_list_flag, writeoff_code, vat_prc, org_id, [timestamp] ) 
	VALUES (  
--		@trx_ctrl_num,  '',  'Discount Adjustment',  '',  0,  
		@trx_ctrl_num,  '',  'Disc Adj - NONSALES',  '',  0,  
		'',  '',  2032,  @date_entered,  @date_applied,  
		@date_doc,  0,  0,  0,  0,  
		@customer_code,  '',  @salesperson_code,  @territory_code,  '',  
		@fob_code,  '',  '',  '',  @price_code,  
		'',  @posting_code,  1,  '',  @tax_code,  
		'',  0.000000,  @adjustment,  0.000000,  @amt_tax,  
		0.000000,  0.000000,  (@adjustment + @amt_tax),  0.000000,  0.000000,  
		0.000000,  0.000000,  0,  0,  0,  
		0,  '',  @user_id,  @addr1,  @addr2,  
		@addr3,  @addr4,  @addr5,  @addr6,  @city,  
		@state,  @postal_code,  @country_code,  '',  '',  
		'',  '',  '',  '',  '',  
		'',  '',  '',  @attention_name,  @attention_phone,  
		0.000000,  0.000000,  0,  '001',  0.000000,  
		0.000000,  @nat_cur_code,  @rate_type_home,  @rate_type_oper,  @home_rate,  
		@oper_rate,  0,  @writeoff_code,  0.000000,  'CVO',  NULL )
	
	IF @@ERROR <> 0 AND @@ROWCOUNT <> 1
	BEGIN
		ROLLBACK TRAN
		SET @error_desc = 'Error creating header' 
		SET @error_no = -2
		RETURN
	END
	

	-- Write detail line
	INSERT arinpcdt (
		[timestamp], trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type,
		location_code, item_code, bulk_flag, date_entered, line_desc,
		qty_ordered, qty_shipped, unit_code, unit_price, unit_cost,
		weight, serial_id, tax_code, gl_rev_acct, disc_prc_flag,
		discount_amt, commission_flag, rma_num, return_code, qty_returned,
		qty_prev_returned, new_gl_rev_acct, iv_post_flag, oe_orig_flag, discount_prc,
		extended_price, calc_tax, reference_code, new_reference_code, cust_po,
		org_id)
	VALUES (
		NULL, @trx_ctrl_num, '', 1, 2032, 
		'', 'Discount Adjustment', 0, @date_entered, 'Discount Adjustment', 
		0, 0, '', @adjustment, 0, 
		0, 0, @tax_code, @account_code, 0, 
		0, 0, '', '', 1, 
		0, '', 1, 0, 0, 
		@adjustment, @amt_tax, '', NULL, NULL, 
		'CVO')

	IF @@ERROR <> 0 AND @@ROWCOUNT <> 1
	BEGIN
		ROLLBACK TRAN
		SET @error_desc = 'Error creating detail' 
		SET @error_no = -3
		RETURN
	END

	-- Write tax details
	INSERT arinptax (
		[timestamp],
		trx_ctrl_num,
		trx_type,
		sequence_id,
		tax_type_code,
		amt_taxable,
		amt_gross,
		amt_tax,
		amt_final_tax)
	VALUES ( 
		NULL, 
		@trx_ctrl_num, 
		2032, 
		1, 
		@tax_code, 
		@adjustment, 
		@adjustment, 
		@amt_tax, 
		@amt_tax )

	IF @@ERROR <> 0 AND @@ROWCOUNT <> 1
	BEGIN
		ROLLBACK TRAN
		SET @error_desc = 'Error creating tax detail' 
		SET @error_no = -4
		RETURN
	END 

	COMMIT TRAN
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[CVO_discount_adjustment_credit_memo_sp] TO [public]
GO
