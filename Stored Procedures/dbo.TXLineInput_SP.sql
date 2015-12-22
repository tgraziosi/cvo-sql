SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO







CREATE PROC [dbo].[TXLineInput_SP]
					@change				smallint, 
					@control_number 	varchar(16), 
					@reference_number 	int, 
					@tax_code			varchar(8), 		
					@quantity			float, 	
					@extended_price		float, 
					@discount_amount	float,
					@tax_type		 	smallint,
					@currency_code	 	varchar(8),

					@validate			smallint = 1
AS
BEGIN
	IF(@change = 0) 
	BEGIN
		IF (@validate = 1)
		BEGIN
			
			IF NOT EXISTS(	SELECT	1
						FROM	artax
						WHERE	tax_code = @tax_code 
						AND	@change = 0
						)
				RETURN 5

			
			IF NOT EXISTS(	SELECT	1
						FROM	glcurr_vw
						WHERE	currency_code = @currency_code
						)
				RETURN 6
		END 

		IF EXISTS(	SELECT 1 
				FROM	#TxLineInput 
				WHERE 	control_number = @control_number
				AND	reference_number = @reference_number
		)
		BEGIN
			
			UPDATE	#TxLineInput
			SET	tax_code = @tax_code,
				quantity = @quantity,
				extended_price = @extended_price,
				discount_amount = @discount_amount,
				currency_code = @currency_code
			WHERE	#TxLineInput.control_number = @control_number
			AND	#TxLineInput.reference_number = @reference_number
		END
		ELSE
		BEGIN
			INSERT	#TxLineInput
			(
				control_number,	reference_number,		tax_code,
				quantity,		extended_price,		discount_amount,
				tax_type,		currency_code
			)
			VALUES
			(
				@control_number,	@reference_number,	@tax_code,
				@quantity,		@extended_price,	@discount_amount,
				@tax_type,		@currency_code
			)
		END
	END
	ELSE IF(@change = 1 OR @change = 2 ) 
	BEGIN
		DELETE	#TxLineInput
		WHERE	control_number = @control_number
		AND	reference_number = @reference_number

		
		IF( @@rowcount = 0 )
			RETURN 2 

		
		IF( @change = 2 )
		BEGIN
			UPDATE	#TxLineInput
			SET	reference_number = reference_number - 1
			WHERE	control_number = @control_number
			AND	reference_number > @reference_number
		END
	END
	ELSE
	BEGIN
		RETURN 4 
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[TXLineInput_SP] TO [public]
GO
