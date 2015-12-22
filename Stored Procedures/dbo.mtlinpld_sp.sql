SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[mtlinpld_sp]	@match_ctrl_num   varchar(16), 
				@po_num           varchar(16),
				@receipt_ctrl_num varchar(16),
				@tax_code         varchar(8),
				@msg_no           smallint OUTPUT
								
AS DECLARE         
	@sequence_id         int,
	@mch_sequence_id     int,
	@po_sequence_id      int,
	@account_code		varchar(32),
	@reference_code	varchar(32),
	@unit_price          float,
	@invoice_unit_price  float,
	@qty_received        float,
	@match_posted_flag	smallint,
	@tolerance_hold_flag	smallint,
	@part_no		varchar(18),
	@part_desc		varchar(60),
	@msg                 varchar(40),
	@line_exists		smallint,
	@line_invalid		smallint,
	@match_dtl_key	char(50),
	@company_id		int,
	@receipt_dtl_key	char(50),
	@tot_qty_received	float,
	@tot_qty_invoiced	float,
	@qty_prev_received float,
	@tot_qty_prev_received  float, 
	@tot_amt_prev_invoiced float,
	@line_tax_code		varchar(8),
	
	@amt_disc			float,
	@amt_freight		float,
	@amt_misc			float,
	@amt_tax_det            float 
	

	
	
	
	
	SELECT @sequence_id = sequence_id,
		@po_sequence_id = po_sequence_id, 
		@company_id = company_id, 
		@receipt_dtl_key = receipt_detail_key,
		@account_code = account_code, 
		@reference_code = reference_code,
		@qty_received = qty_received, 
		@unit_price = unit_price,
		@invoice_unit_price = unit_price,
		
		@line_tax_code = CASE ltrim(rtrim(ISNULL(tax_code,''))) 
			WHEN '' THEN @tax_code 
			ELSE tax_code END,
		
		@amt_disc =	amt_discount,
		@amt_freight = amt_freight,
		@amt_misc =	amt_misc,
		@amt_tax_det = amt_tax
		
   	FROM	epinvdtl  
	WHERE	receipt_ctrl_num = @receipt_ctrl_num	
	AND	invoiced_full_flag = 0
	AND	sequence_id =(SELECT	min(sequence_id)
				FROM	epinvdtl
				WHERE	receipt_ctrl_num = @receipt_ctrl_num	
				AND 	invoiced_full_flag = 0 )

	SELECT @msg_no = 0
	
	
	
	
	WHILE (1=1)
	BEGIN
		IF ( @sequence_id IS NOT NULL )
		BEGIN	
			
			
			
			
			IF NOT EXISTS (	SELECT	'x' 
						FROM	#epmchdtl
						WHERE	match_ctrl_num = @match_ctrl_num
						AND	po_ctrl_num = @po_num
						AND     receipt_dtl_key = @receipt_dtl_key
						AND		match_posted_flag = @sequence_id		
						AND     receipt_ctrl_num = @receipt_ctrl_num	
						AND 	receipt_sequence_id = @sequence_id	)	
			BEGIN
				SELECT @tot_qty_received = ISNULL(qty_received,0)
				FROM	epinvdtl
				WHERE	receipt_ctrl_num = @receipt_ctrl_num
				AND	sequence_id = @sequence_id
			
				SELECT @tot_qty_invoiced = ISNULL(sum(qty_invoiced), 0)
				FROM	epmchdtl
				WHERE	po_ctrl_num = @po_num
				

				AND	receipt_dtl_key = @receipt_dtl_key
				AND 	match_ctrl_num <> @match_ctrl_num
				AND 	receipt_sequence_id = @sequence_id				
			
				IF ( @tot_qty_invoiced < @tot_qty_received )
				BEGIN
					IF NOT EXISTS (SELECT po_ctrl_num 
							FROM	#epmchdtl 
							WHERE	receipt_dtl_key = @receipt_dtl_key
							AND receipt_ctrl_num = @receipt_ctrl_num	
							AND	po_ctrl_num = @po_num 
							AND	match_posted_flag = @sequence_id 		
							AND receipt_sequence_id = @sequence_id)		

					BEGIN
			 			SELECT	@mch_sequence_id = (SELECT MAX(sequence_id) 
		  				FROM	#epmchdtl 
						WHERE  match_ctrl_num = @match_ctrl_num)

						IF(@mch_sequence_id IS NULL )
							SELECT @mch_sequence_id = 1
						ELSE
							SELECT @mch_sequence_id  = @mch_sequence_id + 1




						SELECT @tot_qty_prev_received   = ISNULL(sum(qty_invoiced), 0)
						FROM	epmchdtl
						WHERE	po_ctrl_num = @po_num
						

						AND	receipt_dtl_key = @receipt_dtl_key
						AND 	match_ctrl_num <> @match_ctrl_num
						AND 	receipt_sequence_id = @sequence_id	

						SELECT 	@tot_amt_prev_invoiced =  @tot_qty_prev_received   * @invoice_unit_price		

						SELECT @qty_prev_received  = @tot_qty_prev_received

						IF((@qty_received - @tot_qty_prev_received )  < 0 ) 
						BEGIN
						    SELECT    @qty_prev_received  = @qty_received
						    SELECT    @tot_amt_prev_invoiced = @qty_received * @invoice_unit_price		

						END
						
						SELECT @qty_received = @qty_received - @qty_prev_received

						IF( ((@qty_received) > (0.0) + 0.0000001) )
						BEGIN

						INSERT INTO #epmchdtl
							(
							match_dtl_key,
							match_ctrl_num,
							sequence_id, 
							po_ctrl_num, 
							po_sequence_id, 
							receipt_ctrl_num, 
							receipt_dtl_key, 
							account_code, 
							reference_code, 
							company_id,
							qty_received, 
							qty_invoiced, 
							qty_prev_invoiced, 
							amt_prev_invoiced, 
							unit_price, 
							invoice_unit_price, 
							tolerance_hold_flag,
							match_posted_flag,
							tax_code,
							amt_tax,
							amt_tax_included,
							calc_tax,
							receipt_sequence_id, 	
 							
							amt_discount,
							amt_freight,
							amt_misc,
							amt_tax_exp)
							 								
							VALUES( 
							"MCHKEY0001",  
							@match_ctrl_num, 
							@mch_sequence_id,
							@po_num,
							@po_sequence_id,
							@receipt_ctrl_num,
							@receipt_dtl_key,
							@account_code,
							@reference_code, 
							@company_id,
							@qty_received,
							0.0,
							@tot_qty_prev_received,
							@tot_amt_prev_invoiced,
							@unit_price,
							@invoice_unit_price, 
							0,
							@sequence_id,	
							@line_tax_code,
							0.0,
							0.0,
							0.0,
							@sequence_id,	
 							
							@amt_disc,
							@amt_freight,
							@amt_misc,
							@amt_tax_det)
							 							
						
						IF  @@error != 0
							RETURN -1

					    END 



			
            						
					END 
				END
				ELSE
					SELECT	@msg_no = 3 
			END 
			ELSE 
				SELECT @msg_no = 2
		END 

		


		SELECT @sequence_id = sequence_id,
			@po_sequence_id = po_sequence_id, 
			@company_id = company_id, 
			@receipt_dtl_key = receipt_detail_key,
			@account_code = account_code, 
			@reference_code = reference_code,
			@qty_received = qty_received, 
			@unit_price = unit_price,
			@invoice_unit_price = unit_price,
			
			@line_tax_code = CASE ltrim(rtrim(ISNULL(tax_code,''))) 
				WHEN '' THEN @tax_code 
				ELSE tax_code END,
			@amt_disc =	amt_discount,
			@amt_freight = amt_freight,
			@amt_misc =	amt_misc,
			@amt_tax_det = amt_tax
			
	   	FROM	epinvdtl  
		WHERE	receipt_ctrl_num = @receipt_ctrl_num	
		AND	invoiced_full_flag = 0
		AND	sequence_id > @sequence_id
		AND	sequence_id =(SELECT	min(sequence_id)
					FROM	epinvdtl
					WHERE	receipt_ctrl_num = @receipt_ctrl_num	
					AND 	invoiced_full_flag = 0 
					AND	sequence_id > @sequence_id )

		IF (@@rowcount = 0)
			BREAK
		ELSE
			SELECT @msg_no = 0

	END 

  
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[mtlinpld_sp] TO [public]
GO
