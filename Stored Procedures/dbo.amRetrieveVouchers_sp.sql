SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[amRetrieveVouchers_sp]
(
	@company_id			smCompanyID,		
	@user_id			smUserID,			
	@num_incomplete		smCounter OUTPUT,	


	@num_complete		smCounter OUTPUT,	


	@debug_level		smDebugLevel = 0	
)
AS

DECLARE
	@result					smErrorCode,
	@message				smErrorLongDesc,
 	@rowcount				smCounter,			
 	@voucher_ctrl_num		smControlNumber,	
	@rounding_factor   		float,
	@curr_precision			smallint,
	@completed_flag			smCompletedFlag,
	@completed_date			smApplyDate,
	@completed_by			smUserID,
	@tax_string				smStringText,
	@freight_string			smStringText,
	@discount_string		smStringText,
	@misc_string			smStringText,
	@tax_amount				smMoneyZero,
	@freight_amount			smMoneyZero,
	@discount_amount		smMoneyZero,
	@misc_amount			smMoneyZero,
	@home_currency_code		smCurrencyCode,		
	@trx_currency_code		smCurrencyCode,		
	@rate_home				smCurrencyRate,		
	@apply_date				smApplyDate,
	@amt_net				float,
	@ap_posting_code		varchar(8),
	@vendor_code        	varchar(12),
	@doc_ctrl_num      		varchar(16),
	@sales_tax_acct_code	smAccountCode,
	@disc_given_acct_code	smAccountCode,
	@freight_acct_code		smAccountCode,
	@misc_chg_acct_code		smAccountCode,
	@org_id				varchar(30)




DECLARE @seq_id 	smCounter, 	
	@line_desc	smStdDescription,
	@gl_exp_acct	smAccountCode,
	@reference_code	smAccountReferenceCode,
	@amt_charged	smMoneyZero,
	@qty_received	smQuantity
				
declare @temp_amapnew table (trx_ctrl_num varchar(16))


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amretvch.cpp" + ", line " + STR( 125, 5 ) + " -- ENTRY: "

IF NOT EXISTS(SELECT fac_mask 
				FROM	amfac
				WHERE	company_id	= @company_id)
BEGIN
    EXEC 		amGetErrorMessage_sp 20092, "amretvch.cpp", 131, @error_message = @message out 
   	IF @message IS NOT NULL RAISERROR 	20092 @message 
    RETURN 		20092 
END

SELECT	@num_complete 	= 0,
		@num_incomplete = 0
		



EXEC @result = amGetCurrencyCode_sp 
				@company_id, 
				@home_currency_code   OUTPUT  
IF @result <> 0
	RETURN @result




EXEC @result = amGetCurrencyPrecision_sp 
		@curr_precision    OUTPUT,	
		@rounding_factor   OUTPUT 	

IF @result <> 0
	RETURN @result




EXEC @result = amGetString_sp 
		23,
		@tax_string   OUTPUT 	

IF @result <> 0
	RETURN @result

EXEC @result = amGetString_sp 
		24,
		@discount_string   OUTPUT 	

IF @result <> 0
	RETURN @result

EXEC @result = amGetString_sp 
		25,
		@freight_string   OUTPUT 	

IF @result <> 0
	RETURN @result

EXEC @result = amGetString_sp 
		26,
		@misc_string   OUTPUT 	

IF @result <> 0
	RETURN @result






   
insert into @temp_amapnew
SELECT trx_ctrl_num
FROM	amvchr_vw

SELECT 	@voucher_ctrl_num 	= RTRIM(MIN(trx_ctrl_num))
FROM	@temp_amapnew


WHILE ( LTRIM(@voucher_ctrl_num) IS NOT NULL AND LTRIM(@voucher_ctrl_num) != " " )
BEGIN

	


	SELECT	@trx_currency_code 	= currency_code,
			@rate_home			= rate_home,
			@amt_net			= amt_net,
			@tax_amount			= amt_tax,
			@discount_amount	= (SIGN(-amt_discount) * ROUND(ABS(-amt_discount) + 0.0000001, @curr_precision)),
			@freight_amount		= amt_freight,
			@misc_amount		= amt_misc,
			@ap_posting_code	= posting_code,
			@apply_date			= DATEADD(dd, date_applied - 722815, "1/1/1980"),
			@vendor_code		= vendor_code,
			@doc_ctrl_num		= doc_ctrl_num,
			@org_id  = org_id
	FROM	apvohdr
	WHERE	trx_ctrl_num		= @voucher_ctrl_num

					
	SELECT @rowcount = @@rowcount
	IF @rowcount = 1
	BEGIN

		
		




	   	IF EXISTS (SELECT 	apdet.gl_exp_acct
	   				FROM	apvodet apdet,
						amfac	 fac
	   				WHERE	apdet.trx_ctrl_num 	= @voucher_ctrl_num
					AND		fac.company_id		= @company_id
	   				AND		apdet.gl_exp_acct 	LIKE RTRIM(fac.fac_mask))
			SELECT 	@completed_flag	= 0,
					@completed_date = NULL,
					@completed_by	= 0,
					@num_incomplete	= @num_incomplete + 1
		ELSE
			SELECT 	@completed_flag	= 2,
					@completed_date = GETDATE(),
					@completed_by	= @user_id,
					@num_complete	= @num_complete + 1

			
		IF @debug_level >= 3
			SELECT	voucher 		= @voucher_ctrl_num,
					vendor_code		= @vendor_code,
					doc_ctrl_num	= @doc_ctrl_num,
					completed_date	= @completed_date

		IF @completed_flag	<> 2
		BEGIN
			


			SELECT	@tax_amount		= (SIGN(@tax_amount - (SIGN(ISNULL(SUM(amt_tax), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_tax), 0.0)) + 0.0000001, @curr_precision))) * ROUND(ABS(@tax_amount - (SIGN(ISNULL(SUM(amt_tax), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_tax), 0.0)) + 0.0000001, @curr_precision))) + 0.0000001, @curr_precision)),
				@discount_amount	= (SIGN(@discount_amount + (SIGN(ISNULL(SUM(amt_discount), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_discount), 0.0)) + 0.0000001, @curr_precision))) * ROUND(ABS(@discount_amount + (SIGN(ISNULL(SUM(amt_discount), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_discount), 0.0)) + 0.0000001, @curr_precision))) + 0.0000001, @curr_precision)),
				@freight_amount		= (SIGN(@freight_amount - (SIGN(ISNULL(SUM(amt_freight), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_freight), 0.0)) + 0.0000001, @curr_precision))) * ROUND(ABS(@freight_amount - (SIGN(ISNULL(SUM(amt_freight), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_freight), 0.0)) + 0.0000001, @curr_precision))) + 0.0000001, @curr_precision)),
				@misc_amount		= (SIGN(@misc_amount - (SIGN(ISNULL(SUM(amt_misc), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_misc), 0.0)) + 0.0000001, @curr_precision))) * ROUND(ABS(@misc_amount - (SIGN(ISNULL(SUM(amt_misc), 0.0)) * ROUND(ABS(ISNULL(SUM(amt_misc), 0.0)) + 0.0000001, @curr_precision))) + 0.0000001, @curr_precision))
			FROM	apvodet
			WHERE	trx_ctrl_num		= @voucher_ctrl_num
				
					
			




			IF @trx_currency_code != @home_currency_code
			BEGIN
				IF @debug_level >= 5
					SELECT 	tax_amount 		= @tax_amount,
							misc_amount		= @misc_amount,
							freight_amount	= @freight_amount,
							discount_amount	= @discount_amount
			
				SELECT	@tax_amount 		= (SIGN(@tax_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(@tax_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @curr_precision)),
						@misc_amount 		= (SIGN(@misc_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(@misc_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @curr_precision)),
						@freight_amount 	= (SIGN(@freight_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(@freight_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @curr_precision)),
						@discount_amount 	= (SIGN(@discount_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(@discount_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @curr_precision))
		
				IF @debug_level >= 3
					SELECT 	tax_amount 		= @tax_amount,
							misc_amount		= @misc_amount,
							freight_amount	= @freight_amount,
							discount_amount	= @discount_amount
			
			END
		

			SELECT	@sales_tax_acct_code 	= sales_tax_acct_code,
				@disc_given_acct_code	= disc_given_acct_code,
				@freight_acct_code	= freight_acct_code,
				@misc_chg_acct_code	= misc_chg_acct_code
			FROM	apaccts 
			WHERE	posting_code		= @ap_posting_code

		END

		


		BEGIN TRANSACTION
			
			DELETE 	amapnew
			FROM	amapnew amapnew, apvohdr apvohdr
			WHERE 	amapnew.trx_ctrl_num = @voucher_ctrl_num
			AND	@org_id  = apvohdr.org_id
			
			SELECT	@rowcount = @@rowcount, @result = @@error

			IF @result <> 0
			BEGIN
				ROLLBACK TRANSACTION
				RETURN @result	
			END
			
			








			IF @rowcount >= 1 AND @completed_flag	<> 2
			BEGIN
				INSERT INTO amaphdr
				(
					company_id,
					trx_ctrl_num,
					doc_ctrl_num,
					vendor_code,
					apply_date,
				 	ap_posting_code,
				 	nat_currency_code,
				 	amt_net,
				 	completed_flag,
				 	completed_date,	
					completed_by,
					last_modified_date,
					modified_by,
					org_id
				)
				VALUES
				(
					@company_id,
					@voucher_ctrl_num,
					@doc_ctrl_num,
					@vendor_code,
					@apply_date,
					@ap_posting_code,
				 	@trx_currency_code,
				 	@amt_net,
					@completed_flag,
					@completed_date,
					@completed_by,
					GETDATE(),
					@user_id,
					@org_id
				)

				SELECT @result = @@error
				IF @result <> 0
				BEGIN
					ROLLBACK TRANSACTION
					RETURN @result
				END


				


				
				SELECT @seq_id = 0 

				SELECT 	@seq_id = MIN(sequence_id)
   				FROM	apvodet apdet,	amfac	 fac
   				WHERE	apdet.trx_ctrl_num	= @voucher_ctrl_num
				AND	fac.company_id		= @company_id
   				AND	apdet.gl_exp_acct 	LIKE RTRIM(fac.fac_mask)
				AND	apdet.sequence_id 	> @seq_id

				WHILE  @seq_id IS NOT NULL
				BEGIN
					

					SELECT  @line_desc	= SUBSTRING(line_desc, 1, 40), 
						@gl_exp_acct	= gl_exp_acct,
						@reference_code	= reference_code,
						@amt_charged	= amt_extended,
						@qty_received	= qty_received,
						@org_id		= org_id
					FROM	apvodet
					WHERE	trx_ctrl_num 	= @voucher_ctrl_num
					AND	sequence_id	= @seq_id

					EXEC @result = amch_vwInsert_sp 
							@company_id,		--	@company_id
							@voucher_ctrl_num,	--	@trx_ctrl_num           
							@seq_id,		--	@sequence_id            
							0,			--	@line_id                
							@line_desc,		--	@line_desc              
							@gl_exp_acct,		--	@gl_exp_acct            
							@reference_code,	--	@reference_code         
							@amt_charged,		--	@amt_charged            
							@qty_received,		--	@qty_received           
							NULL,			--	@co_asset_id            
							NULL,			--	@asset_ctrl_num         
							NULL,			--	@line_description       
							NULL,			--	@quantity               
							NULL,			--	@update_asset_quantity	
							NULL,			--	@asset_amount
							NULL,			--	@imm_exp_amount
							NULL,			--	@imm_exp_acct
							NULL,			--	@imm_exp_ref_code
							NULL,			--	@create_item            
							NULL,			--	@activity_type          
							NULL,			--	@apply_date             
							NULL,			--	@asset_tag
							NULL,			--	@item_tag
							NULL,			--	@last_modified_date
							NULL,			--	@modified_by     
							@org_id			--	@org_id

					IF @result <> 0
					BEGIN
						ROLLBACK TRANSACTION
						RETURN @result

					END
					
					SELECT 	@seq_id = MIN(sequence_id)
	   				FROM	apvodet apdet,	amfac	 fac
	   				WHERE	apdet.trx_ctrl_num 	= @voucher_ctrl_num
					AND	fac.company_id		= @company_id
	   				AND	apdet.gl_exp_acct 	LIKE RTRIM(fac.fac_mask)
					AND	apdet.sequence_id 	> @seq_id

				END


				



				IF (ABS((@tax_amount)-(0.0)) > 0.0000001)
				BEGIN
					INSERT INTO amapchrg
					(
						company_id,
						trx_ctrl_num,
						sequence_id,
					 	line_desc,
						gl_exp_acct,
						reference_code,
						amt_charged,
						last_modified_date,
						modified_by
					)
					VALUES
					(
						@company_id,
						@voucher_ctrl_num,
						-1,
						@tax_string,
						@sales_tax_acct_code,
						"",
						@tax_amount,
						GETDATE(),
						@user_id
					)

				SELECT @result = @@error
				IF @result <> 0
					BEGIN
						ROLLBACK TRANSACTION
						RETURN @result
					END
				END


				IF (ABS((@discount_amount)-(0.0)) > 0.0000001)
				BEGIN
					INSERT INTO amapchrg
					(
						company_id,
						trx_ctrl_num,
						sequence_id,
					 	line_desc,
						gl_exp_acct,
						reference_code,
						amt_charged,
						last_modified_date,
						modified_by
					)
					VALUES
					(
						@company_id,
						@voucher_ctrl_num,
						-2,
						@discount_string,
						@disc_given_acct_code,
						"",
						@discount_amount,
						GETDATE(),
						@user_id
					)

					SELECT @result = @@error
					IF @result <> 0
					BEGIN
						ROLLBACK TRANSACTION
						RETURN @result
					END
				END

				IF (ABS((@freight_amount)-(0.0)) > 0.0000001)
				BEGIN
					INSERT INTO amapchrg
					(
						company_id,
						trx_ctrl_num,
						sequence_id,
					 	line_desc,
						gl_exp_acct,
						reference_code,
						amt_charged,
						last_modified_date,
						modified_by
					)
					VALUES
					(
						@company_id,
						@voucher_ctrl_num,
						-3,
						@freight_string,
						@freight_acct_code,
						"",
						@freight_amount,
						GETDATE(),
						@user_id
					)

					SELECT @result = @@error
					IF @result <> 0
					BEGIN
						ROLLBACK TRANSACTION
						RETURN @result
					END
				 END

				IF (ABS((@misc_amount)-(0.0)) > 0.0000001)
				BEGIN
					INSERT INTO amapchrg
					(
						company_id,
						trx_ctrl_num,
						sequence_id,		   
					 	line_desc,
						gl_exp_acct,
						reference_code,
						amt_charged,
						last_modified_date,
						modified_by
					)
					VALUES
					(
						@company_id,
						@voucher_ctrl_num,
						-4,
						@misc_string,
						@misc_chg_acct_code,
						"",
						@misc_amount,
						GETDATE(),
						@user_id
					)

					SELECT @result = @@error
					IF @result <> 0
					BEGIN
						ROLLBACK TRANSACTION
						RETURN @result
					END
				END
			END

		COMMIT TRANSACTION

	END
	ELSE
	BEGIN
		


	
		DELETE 	amapnew
		FROM	amapnew amapnew, apvohdr apvohdr
		WHERE 	amapnew.trx_ctrl_num = @voucher_ctrl_num
		AND		@org_id  = apvohdr.org_id
			
		SELECT @result = @@error
		IF @result <> 0
			RETURN @result
	END
	


	SELECT 	@voucher_ctrl_num	= MIN(trx_ctrl_num)      
	FROM	@temp_amapnew
	WHERE	trx_ctrl_num		> @voucher_ctrl_num
	
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amretvch.cpp" + ", line " + STR( 624, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amRetrieveVouchers_sp] TO [public]
GO
