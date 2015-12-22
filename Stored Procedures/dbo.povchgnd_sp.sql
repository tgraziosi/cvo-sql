SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[povchgnd_sp] 
	@match_ctrl_num 		varchar(16), 
	@trx_ctrl_num 		varchar(16), 
	@sysdate 			int, 
	@code_1099 			varchar(8),
	@company_id 			smallint, 
	@vendor_code 			varchar(12),
	@default_aprv_code 		varchar(8), 
	@invoice_receive_date 	int,
	@amt_due 			float, 
	@user_id 		int,
	@date_applied 		int,
 	@allow_vchr_edit_flag	smallint, 
	@error_flag 			smallint OUTPUT
AS

 DECLARE
	@receipt_ctrl_num varchar(16),
	@receipt_dtl_key varchar(50),
	@po_ctrl_num varchar(16), 
	@po_sequence_id int,
	@account_code varchar(32),
	@unit_price float,
	@invoice_unit_price float, 
	@qty_prev_invoiced float,
	@qty_invoiced float, 
	@amt_prev_invoiced float,
	@match_flag smallint, 
	@location_code varchar(8),
	@item_code varchar(18), 
	@qty_received float,
	@tax_code varchar(8), 
	@unit_code varchar(8),
	@amt_extended float, 
	@line_desc varchar(60),
	@sequence_id int,
	@counter		int, 
	@resulting_status varchar(8),
	@trx_type_code varchar(8), 
	@full_count int,
	@error_string varchar(10), 
	@error_num varchar(8),
	@err_msg varchar(40), 
	@pomchrec_amt_ext float, 
	@retval 	 int,
	@receive_ok		 int,
	@return_code 			smallint,
	@curr_precision		smallint,
	@calc_tax			float,
	@home_cur_code		varchar(8),
	@ap_nat_cur_code 		varchar(8),
	@rate_type_home		varchar(8),
	@nat_cur_code			varchar(8),
	@rate_home			float,
	@differences			smallint,
	@reclin_unit_price		float,
	@home_reclin_unit_price	float,
	@home_match_unit_price	float, 
	@conv_po_qty_received	float,
	@iv_trx_ctrl_num		varchar(16),
	@adjust_amt			float 

 	
 	SELECT @sequence_id = 0,
		@counter = 0,
		@full_count = 0, 
		@trx_type_code = "",
		@resulting_status = "",
		@home_cur_code = "",
		@ap_nat_cur_code = "",
		@rate_type_home = "",
		@nat_cur_code = "",
		@rate_home = 1.0





			


			
	SELECT @home_cur_code = home_currency
	FROM 	 glco a
	
	SELECT	 @ap_nat_cur_code = nat_cur_code,
		 @rate_type_home = rate_type_home
	FROM	 apvend
	WHERE vendor_code = @vendor_code

	SELECT @nat_cur_code = @ap_nat_cur_code

	IF @nat_cur_code = @home_cur_code
		SELECT @rate_home = 1.0
	ELSE
	BEGIN	
		EXEC @return_code = CVO_Control..mccurate_sp	
						@date_applied, 
						@nat_cur_code, 
						@home_cur_code, 
						@rate_type_home,
						@rate_home OUTPUT,
						0
		IF @return_code != 0
			RETURN -1
	END
			
			
 
 	
 	WHILE 1=1 
	BEGIN
 		SET ROWCOUNT 1 

		SELECT @sequence_id = sequence_id, 
			@po_ctrl_num = po_ctrl_num,
			@po_sequence_id = po_sequence_id, 
			@receipt_dtl_key = receipt_dtl_key,
			@account_code = account_code, 
			@qty_received = qty_received, 
			@unit_price = unit_price, 
			@invoice_unit_price = invoice_unit_price,
			@qty_prev_invoiced = qty_prev_invoiced, 
			@qty_invoiced = qty_invoiced, 
			@amt_prev_invoiced = amt_prev_invoiced, 
			@qty_received = qty_received,
			@tax_code = tax_code,
			@calc_tax = calc_tax 
		FROM 	#epvchlin
		WHERE 	match_ctrl_num = @match_ctrl_num
		AND 	sequence_id > @counter
		ORDER BY sequence_id 
 
		IF @@rowcount = 0
			BREAK

		SET ROWCOUNT 0

		SELECT @curr_precision = g.curr_precision
		FROM	glcurr_vw g, epmchhdr m
		WHERE	m.match_ctrl_num = @match_ctrl_num
		AND	m.nat_cur_code = g.currency_code
			
		
		SELECT @amt_extended = (SIGN(( @invoice_unit_price * @qty_invoiced )) * ROUND(ABS(( @invoice_unit_price * @qty_invoiced )) + 0.0000001, @curr_precision))

		SELECT @item_code = item_code,
			@unit_code = unit_code,
			@line_desc = item_desc
		FROM epinvdtl
		WHERE receipt_detail_key = @receipt_dtl_key


		SELECT	@location_code = location_code
		FROM	apvend
		WHERE	vendor_code = @vendor_code

		EXEC @retval = appoxdet_sp 
			@trx_ctrl_num, 
			4091, 
			@sequence_id,
			@location_code, 
			@item_code, 
			@qty_received,
			@qty_invoiced, 
			0,						 
			0,						
			@default_aprv_code, 
	 		@tax_code, 
			"", 					
			@code_1099, 
			@receipt_dtl_key, 
			@po_ctrl_num, 
			@unit_code,	
			@invoice_unit_price, 
			0, 						 
			0,						
			0,						 
			0,						 
			@amt_extended, 
			@account_code, 
			"", 					 
			"",						
			@line_desc, 
			0,						 
			@company_id,
			0,						 
			@date_applied, 
			@user_id ,
			@calc_tax 

		if @retval != 0 
		BEGIN
			SELECT @error_num = convert(varchar(8), @retval)
			SELECT @err_msg = "Error " + @error_num + " in appoxdet"
			raiserror 20001 @err_msg
			RETURN -1
		END

		UPDATE epmchdtl
		SET match_posted_flag = 1
		WHERE match_ctrl_num = @match_ctrl_num
		AND	sequence_id = @sequence_id
		IF @@error != 0 
			RETURN -1
		
		UPDATE epinvdtl
		SET amt_invoiced = amt_invoiced + @amt_extended,
			qty_invoiced = qty_invoiced + @qty_invoiced
		
		WHERE receipt_detail_key = @receipt_dtl_key
		IF @@error != 0 
			RETURN -1

		UPDATE	epinvdtl
		SET	invoiced_full_flag = 1
		WHERE	((qty_received - qty_invoiced) <= (0.0) + 0.0000001)
		AND	receipt_detail_key = @receipt_dtl_key
		IF @@error != 0 
			RETURN -1
		
		SELECT	@receipt_ctrl_num = receipt_ctrl_num
		FROM	epmchdtl
		WHERE	match_ctrl_num = @match_ctrl_num
		AND	sequence_id = @sequence_id
		IF @@error != 0 
			RETURN -1
		
		UPDATE epinvhdr
		SET invoiced_full_flag = 1
		WHERE receipt_ctrl_num = @receipt_ctrl_num
		AND NOT EXISTS (SELECT 'x' FROM epinvdtl
		WHERE receipt_ctrl_num = @receipt_ctrl_num
		AND invoiced_full_flag = 0)
 		IF @@error != 0 
			RETURN -1
		
		SELECT @counter = @counter + 1
			








		 
	END 
 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[povchgnd_sp] TO [public]
GO
