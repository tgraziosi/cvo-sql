SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROC [dbo].[APPAProcessDebitMemos_sp]    @user_id	 smallint,
										@debug_level smallint = 0

AS
	DECLARE
			@dm_trx_num			varchar(16),
			@user_trx_type_code varchar(8),
			@current_date 		int,
			@result int,

			@trx_ctrl_num		varchar(16),
			@doc_ctrl_num		varchar(16),
			@po_ctrl_num 		varchar(16),
			@vend_order_num		varchar(20),
			@date_aging			int,
			@date_due			int,
			@date_doc			int,
			@date_applied		int,
			@date_received		int,
			@date_required		int,
			@date_discount  	int,
			@posting_code   	varchar(8),
			@vendor_code    	varchar(12),
			@pay_to_code    	varchar(8),
			@branch_code    	varchar(8),
			@class_code     	varchar(8),
			@approval_code  	varchar(8),
			@comment_code   	varchar(8),
			@fob_code       	varchar(8),
			@terms_code     	varchar(8),
			@tax_code       	varchar(8),
			@recurring_code 	varchar(8),
			@payment_code		varchar(8),
			@one_time_vend_flag smallint,
			@one_check_flag     smallint,
			@amt_gross          float,
			@amt_discount       float,
			@amt_tax            float,
			@amt_freight        float,
			@amt_misc           float,
			@amt_net            float,
			@amt_tax_included	float,
			@doc_desc           varchar(40),
			@intercompany_flag	smallint,
			@company_code      	varchar(8),
			@nat_cur_code		varchar(8),
			@rate_type_home		varchar(8),
			@rate_type_oper		varchar(8),
			@rate_home			float,
			@rate_oper			float,
			@sequence_id		int,
			@seq_id		        int, -- Rev.1.0
			@location_code     	varchar(8),
			@item_code         	varchar(30),
			@bulk_flag         	smallint,
			@qty_ordered       	float,
			@qty_received      	float,
			@return_code       	varchar(8),
			@code_1099         	varchar(8),
			@unit_code         	varchar(8),
			@unit_price        	float,
			@amt_extended      	float,
			@calc_tax	       	float,
			@gl_exp_acct       	varchar(32),
			@line_desc      	varchar(60),
			@serial_id         	int,
			@po_orig_flag      	smallint,
			@rec_company_code  	varchar(8),
			@reference_code    	varchar(32),
			@company_id			smallint,
			@tax_type_code		varchar(8),
			@amt_taxable 		float,
			@amt_final_tax 		float,
                        @org_id                 varchar(30),        
			@str_msg		varchar(255)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appapdm.cpp" + ", line " + STR( 127, 5 ) + " -- ENTRY: "

SELECT @company_code = company_code
FROM glco


EXEC appdate_sp @current_date OUTPUT


CREATE TABLE #dmheader (
						trx_ctrl_num 		varchar(16),
						doc_ctrl_num 		varchar(16),
						po_ctrl_num 		varchar(16),
						vend_order_num  	varchar(20),
						date_aging 			int,
						date_due 			int,
						date_doc 			int,
						date_applied		int,
						date_received		int,
						date_required		int,
						date_discount		int,
						posting_code        varchar(8),
						vendor_code        	varchar(12),
						pay_to_code        	varchar(8),
						branch_code        	varchar(8),
						class_code          varchar(8),
						approval_code       varchar(8),
						comment_code        varchar(8),
						fob_code            varchar(8),
						terms_code          varchar(8),
						tax_code            varchar(8),
						recurring_code      varchar(8),
						payment_code		varchar(8),
						one_time_vend_flag  smallint,
						one_check_flag    	smallint,
						amt_gross           float,
						amt_discount      	float,
						amt_tax             float,
						amt_freight       	float,
						amt_misc            float,
						amt_net             float,
						amt_tax_included	float,
						doc_desc            varchar(40),
						intercompany_flag 	smallint,
						nat_cur_code		varchar(8),
					    rate_type_home		varchar(8),
					    rate_type_oper		varchar(8),
					    rate_home			float,
					    rate_oper			float,
						mark_flag 			smallint,
                                                org_id                  varchar (30)        
						)

CREATE TABLE #dmdetail (
						trx_ctrl_num  		varchar(16),
						sequence_id 		int,
						location_code     	varchar(8),
						item_code         	varchar(30),
						tax_code			varchar(8),
						qty_ordered       	float,
						qty_received      	float,
						return_code       	varchar(8),
						code_1099         	varchar(8),
						unit_code         	varchar(8),
						unit_price        	float,
						amt_discount      	float,
						amt_freight       	float,
						amt_tax           	float,
						amt_misc  		  	float,
						amt_extended      	float,
						calc_tax	      	float,
						gl_exp_acct       	varchar(32),
						line_desc      		varchar(60),
						serial_id         	int,
						po_orig_flag      	smallint,
						rec_company_code  	varchar(8),
						company_id			smallint,
						reference_code    	varchar(32),
						mark_flag 			smallint,
                                                org_id                  varchar (30)        
						)



CREATE TABLE  	#dmtax   (
		trx_ctrl_num		varchar(16),
		trx_type		smallint,
		sequence_id		int,
		tax_type_code		varchar(8),
		amt_taxable		float,
		amt_gross		float,
		amt_tax			float,
		amt_final_tax		float,
		trx_state 		smallint NULL, 
		mark_flag       	smallint NULL
		)



SELECT @user_trx_type_code = user_trx_type_code
FROM apusrtyp
WHERE system_trx_type = 4092
AND dm_type = 1



INSERT #dmheader (	trx_ctrl_num,
					doc_ctrl_num,
					po_ctrl_num,
					vend_order_num,
					date_aging,
					date_due,
					date_doc,
					date_applied,
					date_received,
					date_required,
					date_discount,
					posting_code, 
					vendor_code,
					pay_to_code,
					branch_code,
					class_code,
					approval_code,
					comment_code,
					fob_code,
					terms_code,
					tax_code,
					recurring_code,
					payment_code,
					one_time_vend_flag,
					one_check_flag,
					amt_gross,
					amt_discount,
					amt_tax,
					amt_freight,
					amt_misc,
					amt_net,
					amt_tax_included,
					doc_desc,
					intercompany_flag,
					nat_cur_code,
				    rate_type_home,
				    rate_type_oper,
				    rate_home,
				    rate_oper,  
					mark_flag,
                                        org_id        
				 )
SELECT	DISTINCT	a.trx_ctrl_num,
					a.doc_ctrl_num,
					a.po_ctrl_num,
					a.vend_order_num,
					a.date_aging,
					a.date_due,
					a.date_doc,
					b.date_applied,
					a.date_received,
					a.date_required,
					a.date_discount,
					a.posting_code, 
					a.vendor_code,
					a.pay_to_code,
					a.branch_code,
					a.class_code,
					a.approval_code,
					a.comment_code,
					a.fob_code,
					a.terms_code,
					a.tax_code,
					a.recurring_code,
					a.payment_code,
					a.one_time_vend_flag,
					a.one_check_flag,
					a.amt_gross,
					a.amt_discount,
					a.amt_tax,
					a.amt_freight,
					a.amt_misc,
					a.amt_net,
					a.amt_tax_included,
					a.doc_desc,
					a.intercompany_flag,
					a.currency_code,
					a.rate_type_home,
					a.rate_type_oper,
					a.rate_home,
					a.rate_oper,
					0,
                                        b.org_id        
FROM	apvohdr a, #appapyt_work b, #appapdt_work c
WHERE 	b.trx_ctrl_num = c.trx_ctrl_num
AND		c.apply_to_num = a.trx_ctrl_num
AND		b.void_type = 2


INSERT #dmdetail (	trx_ctrl_num,
					sequence_id,
					location_code,
					item_code,
					tax_code,
					qty_ordered,
					qty_received,
					return_code,
					code_1099,
					unit_code,
					unit_price, 
					amt_discount,
					amt_freight,
					amt_tax,
					amt_misc,  
					amt_extended,
					calc_tax,
					gl_exp_acct,
					line_desc,
					serial_id,
					po_orig_flag,
					rec_company_code,
					company_id,
					reference_code,
					mark_flag,
                                        org_id        
				)
SELECT 				a.trx_ctrl_num,
					a.sequence_id,
					a.location_code,
					a.item_code,
					a.tax_code,
					a.qty_ordered,
					a.qty_received,
					"",
					a.code_1099,
					a.unit_code,
					a.unit_price,
					a.amt_discount,
					a.amt_freight,
					a.amt_tax,
					a.amt_misc,  
					a.amt_extended,
					a.calc_tax,
					a.gl_exp_acct,
					a.line_desc,
					a.serial_id,
					a.po_orig_flag,
					a.rec_company_code,
					c.company_id,
					a.reference_code,
					0,
                                        a.org_id        
FROM	apvodet a, #dmheader b, glcomp_vw c
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.rec_company_code = c.company_code



INSERT	#dmtax (
		trx_ctrl_num		,
		trx_type		,
		sequence_id		,
		tax_type_code		,
		amt_taxable		,
		amt_gross		,
		amt_tax			,
		amt_final_tax		,
		trx_state 		, 
		mark_flag       	
		)
SELECT	a.trx_ctrl_num,
	4092,
	0,
	a.tax_type_code,
	a.amt_taxable,
	a.amt_gross,
	a.amt_tax,
    a.amt_tax,
	2,
	b.mark_flag
FROM	aptrxtax a, #dmheader b
WHERE	a.trx_ctrl_num 	= b.trx_ctrl_num
AND	a.trx_type = 4091



WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
		  SELECT @trx_ctrl_num = trx_ctrl_num,
				 @doc_ctrl_num = doc_ctrl_num,
				 @po_ctrl_num = po_ctrl_num,
				 @vend_order_num = vend_order_num,
				 @date_aging = date_aging,
				 @date_due = date_due,
				 @date_doc = date_doc,
				 @date_applied = date_applied,
				 @date_received = date_received,
				 @date_required = date_required,
				 @date_discount = date_discount,
				 @posting_code = posting_code, 
				 @vendor_code = vendor_code,
				 @pay_to_code = pay_to_code,
				 @branch_code = branch_code,
				 @class_code = class_code,
				 @approval_code = approval_code,
				 @comment_code = comment_code,
				 @fob_code = fob_code,
				 @terms_code = terms_code,
				 @tax_code = tax_code,
				 @recurring_code = recurring_code,
				 @payment_code = payment_code,
				 @one_time_vend_flag = one_time_vend_flag,
				 @one_check_flag = one_check_flag,
				 @amt_gross = amt_gross,
				 @amt_discount = amt_discount,
				 @amt_tax = amt_tax,
				 @amt_freight = amt_freight,
				 @amt_misc = amt_misc,
				 @amt_net = amt_net,
				 @amt_tax_included = amt_tax_included,
				 @doc_desc = doc_desc,
				 @intercompany_flag = intercompany_flag,
				 @nat_cur_code = nat_cur_code,
				 @rate_type_home = rate_type_home,
				 @rate_type_oper = rate_type_oper,
				 @rate_home = rate_home,
				 @rate_oper = rate_oper,
                                 @org_id = org_id        
		  FROM #dmheader
		  WHERE mark_flag = 0
	  
	  
	  	  IF @@rowcount = 0 BREAK
	  
	  SET ROWCOUNT 0

	      	SELECT @dm_trx_num = NULL

		EXEC appgetstring_sp "STR_STOP_PAYMENT", @str_msg OUT
	
			EXEC @result = apvocrh_sp
					4000,
					2,       
					@dm_trx_num  OUTPUT,  
					4092,                  
					@doc_ctrl_num,
					@trx_ctrl_num,
					@user_trx_type_code,
					" ",
					@po_ctrl_num,
					@vend_order_num,
					" ",
					@date_applied,
					@date_aging,
					@date_due,
					@date_doc,
					@current_date,
					@date_received,
					@date_required,
					0,
					@date_discount,
					@posting_code, 
					@vendor_code,
					@pay_to_code,
					@branch_code,
					@class_code,
					@approval_code,
					@comment_code,
					@fob_code,
					@terms_code,
					@tax_code,
					@recurring_code,
					" ",
					@payment_code,
					0,
					0,
					0,
					0,
					1,
					0,
					0,
					0,
					@one_time_vend_flag,
					@one_check_flag,
					@amt_gross,
					@amt_discount,
					@amt_tax,
					@amt_freight,
					@amt_misc,
					@amt_net,
					0,
					@amt_net,
				    0,
				 	@amt_tax_included,
					0,
				    @doc_desc,
					@str_msg,                   
					@user_id,
					0,
					" ",    
					" ",    
					" ",    
					" ",    
					" ",    
					" ",    
					" ",   
					" ",   
					@intercompany_flag,
					@company_code,
					0,
					" ",
					@nat_cur_code,
					@rate_type_home,
					@rate_type_oper,
					@rate_home,
					@rate_oper,
					@amt_net,
                                        @org_id        
			
			IF(@result != 0)
				RETURN @result
				
			


			SELECT @seq_id = 1				


			WHILE (1=1)
				BEGIN
					SET ROWCOUNT 1
						SELECT 	@sequence_id = sequence_id,
								@location_code = location_code,
								@item_code = item_code,
								@tax_code = tax_code,
								@qty_ordered = qty_ordered,
								@qty_received = qty_received,
								@return_code = return_code,
								@code_1099 = code_1099,
								@unit_code = unit_code,
								@unit_price = unit_price,
								@amt_discount = amt_discount,
								@amt_freight = amt_freight,
								@amt_tax = amt_tax,
								@amt_misc = amt_misc,  
								@amt_extended = amt_extended,
								@calc_tax = calc_tax,
								@gl_exp_acct = gl_exp_acct,
								@line_desc = line_desc,
								@serial_id = serial_id,
								@po_orig_flag = po_orig_flag,
								@rec_company_code = rec_company_code,
								@company_id = company_id,
								@reference_code = reference_code,
                                                                @org_id= org_id        
						FROM #dmdetail
						WHERE trx_ctrl_num = @trx_ctrl_num
						AND     sequence_id		= @seq_id  -- Rev 1.0
						AND mark_flag = 0

						IF @@rowcount = 0 break

					SET ROWCOUNT 0

						EXEC @result = apvocrd_sp
							   4000,
							   2,      
							   @dm_trx_num,  
							   4092,  
							   @sequence_id,   
							   @location_code,   
							   @item_code,   
							   0,
							   @qty_ordered,   
							   @qty_received,   
							   @qty_received,   
							   0,
							   @approval_code,      
							   @tax_code,   
							   @return_code,   
							   @code_1099,   
							   @po_ctrl_num,   
							   @unit_code,   
							   @unit_price,   
							   @amt_discount,   
							   @amt_freight,   
							   @amt_tax,   
							   @amt_misc,   
							   @amt_extended,   
							   @calc_tax,
							   @current_date,   
							   @gl_exp_acct,   
							   "",   
							   " ",            
							   @line_desc,   
							   @serial_id,   
							   @company_id,   
							   1,        
							   @po_orig_flag,   
							   @rec_company_code,   
							   "",
							   @reference_code,              
							   "",
                                                           @org_id          

			IF(@result != 0)
				RETURN @result


				SET ROWCOUNT 1
				
				UPDATE #dmdetail
				SET mark_flag = 1
				WHERE trx_ctrl_num = @trx_ctrl_num
				AND     sequence_id		= @seq_id -- Rev 1.0
				AND mark_flag = 0
				
				SELECT @seq_id = @seq_id + 1  --Rev 1.0
				
				SET ROWCOUNT 0
			END -- Rev 1.0
			


			SELECT @seq_id = 1 --Rev 1.0

			WHILE (1=1)   -- Rev 1.0

				BEGIN  -- Rev 1.0


					SET ROWCOUNT 1

						SELECT 	
							@tax_type_code 	= tax_type_code,
							@amt_taxable 	= amt_taxable,				
							@amt_gross 	= amt_gross,	
							@amt_tax 	= sum(amt_tax),
							@amt_final_tax 	= sum(amt_final_tax)
						FROM 	#dmtax
						WHERE 	trx_ctrl_num 	= @trx_ctrl_num						
						AND 	mark_flag 	= 0
						GROUP BY trx_ctrl_num,
								 trx_type,
								 tax_type_code,
								 amt_taxable,
								 amt_gross

						IF @@rowcount = 0 break

					SET ROWCOUNT 0

						EXEC @result = apvocrt_sp
								4000,	
								2,	
								@dm_trx_num,
								4092,	
								0,	
								@tax_type_code,
								@amt_taxable,	
								@amt_gross,	
								@amt_tax,
								@amt_final_tax

						IF(@result != 0)
							RETURN @result


					SET ROWCOUNT 1

						UPDATE 	#dmtax
						SET 	mark_flag = 1
						WHERE 	trx_ctrl_num = @trx_ctrl_num
				

						AND 	mark_flag = 0	
				

						
						SELECT @seq_id = @seq_id + 1
					
					SET ROWCOUNT 0



				END

			SET ROWCOUNT 1
			UPDATE #dmheader
			SET mark_flag = 1
			WHERE mark_flag = 0
			SET ROWCOUNT 0

	END

DROP TABLE #dmheader
DROP TABLE #dmdetail

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appapdm.cpp" + ", line " + STR( 722, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAProcessDebitMemos_sp] TO [public]
GO
