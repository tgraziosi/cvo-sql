SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_vendor_payment_sp]		@contract_ctrl_num		VARCHAR(16),
																				@vendor_code					VARCHAR(12),
																				@void_flag									INT,
																				@check_num						VARCHAR(16),
																				@nat_cur_code					VARCHAR(8),
																				@amount								FLOAT ,
						@userid				INT = 0
	

AS

	DECLARE 	@sequence_id					INT,
						@rate_type_home				VARCHAR(8),
						@rate_type_oper				VARCHAR(8),
						@rate_home						FLOAT,
						@rate_oper						FLOAT,
						@home_amount					FLOAT,
						@oper_amount					FLOAT,
						@home_currency_code		VARCHAR(8),
						@oper_currency_code		VARCHAR(8),
						@divide_flag_home			INT,
						@divide_flag_oper			INT,
						@result								INT,
						@today								INT,
						@mcrate_error					VARCHAR(100),
						@paid_to_date					FLOAT,
						@currency_type  			VARCHAR(5),
						@class_code						VARCHAR(8)

	SELECT	@today = DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906

	
	SELECT 		@home_currency_code	= home_currency,
						@oper_currency_code	= oper_currency
	FROM 			glco


	SELECT 		@rate_type_home = rate_type_home,
						@rate_type_oper	= rate_type_oper
	FROM 			apco

	SELECT 		@class_code = vend_class_code
	FROM			apvend
	WHERE			vendor_code = @vendor_code

	EXEC @result = CVO_Control..mccurate_sp	@today,
																				@nat_cur_code,	
																				@home_currency_code,		
																				@rate_type_home,
																				@rate_home	OUTPUT,
																				0,
																				@divide_flag_home	OUTPUT
			
	IF @result	<> 0
		BEGIN /* sp returned an error */
			SELECT	@mcrate_error = 
				CASE @result
					WHEN 100	THEN 	'Rate retrived was <= 0'
					WHEN 101	THEN 	'to currency was not defined in mccurr'
					WHEN 102	THEN	'No currency definition defined in mccurate'
					WHEN 103	THEN 	'Currency rate is invalid at this time'
					ELSE	'Currency Conversion Failed'
				END

			SELECT @result, @mcrate_error, 0.00
			RETURN
		END


	EXEC @result = CVO_Control..mccurate_sp	@today,
																				@nat_cur_code,	
																				@oper_currency_code,		
																				@rate_type_oper,
																				@rate_oper	OUTPUT,
																				0,
																				@divide_flag_oper	OUTPUT
			
	IF @result	<> 0
		BEGIN /* sp returned an error */
			SELECT	@mcrate_error = 
				CASE @result
					WHEN 100	THEN 	'Rate retrived was <= 0'
					WHEN 101	THEN 	'to currency was not defined in mccurr'
					WHEN 102	THEN	'No currency definition defined in mccurate'
					WHEN 103	THEN 	'Currency rate is invalid at this time'
					ELSE	'Currency Conversion Failed'
				END

			SELECT @result, @mcrate_error, 0.00
			RETURN
		END


	SELECT @currency_type = text_value 
	FROM pr_config 
	WHERE item_name = 'CURRENCY'


	IF @rate_home <> 0
		BEGIN
			IF  @divide_flag_home = 0
				SELECT @home_amount = ISNULL((@amount * ABS(@rate_home) ), 0)
			ELSE
				SET @home_amount = ISNULL((@amount / ABS(@rate_home) ), 0)
		END

	IF @rate_oper <> 0
		BEGIN
			IF  @divide_flag_oper = 0
				SELECT @oper_amount = ISNULL((@amount * ABS(@rate_oper) ), 0)
			ELSE
				SET @oper_amount = ISNULL((@amount / ABS(@rate_oper) ), 0)
		END


	IF @userid = 0
	BEGIN
		SELECT 		@userid = [user_id]
		FROM			CVO_Control..smusers
		WHERE			[user_name] = SUSER_SNAME()
	END

	BEGIN TRAN

		SELECT @sequence_id = MAX(sequence_id) + 1 FROM pr_vendor_payments

		INSERT [pr_vendor_payments] (	[contract_ctrl_num],
																	[sequence_id],
																	[vendor_code],
																	[void_flag],
																	[check_num],
																	[nat_cur_code],
																	[amount],
																	[rate_type_home],
																	[rate_type_oper],
																	[rate_home],
																	[rate_oper],
																	[home_amount],
																	[oper_amount],
																	[userid],
																	[date_entered])

		SELECT	@contract_ctrl_num,
						ISNULL(@sequence_id,1),
						@vendor_code,
						@void_flag,
						@check_num,
						@nat_cur_code,
						@amount,
						@rate_type_home,
						@rate_type_oper,
						@rate_home,
						@rate_oper,
						@home_amount,
						@oper_amount,
						@userid,
						@today
	
		
		IF @@ERROR <> 0
			BEGIN
				SELECT @@ERROR, ' ', 0.00
				ROLLBACK TRAN
				RETURN
			END

		UPDATE pr_vendors
		SET amount_paid_to_date_home = ISNULL(amount_paid_to_date_home,0) + @home_amount,
				amount_paid_to_date_oper = ISNULL(amount_paid_to_date_oper,0) + @oper_amount
		WHERE	vendor_code = @vendor_code
		AND	contract_ctrl_num = @contract_ctrl_num

		UPDATE pr_contracts
		SET amount_paid_to_date_home = ISNULL(amount_paid_to_date_home,0) + @home_amount,
				amount_paid_to_date_oper = ISNULL(amount_paid_to_date_oper,0) + @oper_amount
		WHERE	contract_ctrl_num = @contract_ctrl_num

		IF @@ERROR <> 0
			BEGIN
				SELECT @@ERROR, ' ', 0.00
				ROLLBACK TRAN
				RETURN
			END


		IF ( ISNULL( DATALENGTH( LTRIM( RTRIM( @class_code ) ) ),0 ) > 0 )
			BEGIN
				UPDATE pr_vendor_class
				SET amount_paid_to_date_home = ISNULL(amount_paid_to_date_home,0) + @home_amount,
						amount_paid_to_date_oper = ISNULL(amount_paid_to_date_oper,0) + @oper_amount
				WHERE	vendor_class = @class_code
				AND	contract_ctrl_num = @contract_ctrl_num
		
				IF @@ERROR <> 0
					BEGIN
						SELECT @@ERROR, ' ', 0.00
						ROLLBACK TRAN
						RETURN
					END
			END
	
		IF  ( UPPER( @currency_type ) = 'HOME' )
			SELECT	@paid_to_date = SUM( home_amount )
			FROM	pr_vendor_payments
			WHERE	contract_ctrl_num = @contract_ctrl_num
			AND		vendor_code = @vendor_code
	
		IF  ( UPPER( @currency_type ) = 'OPER' )
			SELECT	@paid_to_date = SUM( oper_amount )
			FROM	pr_vendor_payments
			WHERE	contract_ctrl_num = @contract_ctrl_num
			AND		vendor_code = @vendor_code
	
		SELECT 0, ' ', ISNULL(@paid_to_date, 0.00)

	COMMIT TRAN

GO
GRANT EXECUTE ON  [dbo].[pr_vendor_payment_sp] TO [public]
GO
