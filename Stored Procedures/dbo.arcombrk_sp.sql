SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC	[dbo].[arcombrk_sp]	@salesperson_code	varchar(8), 
				@serial_id		int,
				@calc_type		smallint, 
				@commission_code	varchar(8),
				@b_commissionable	float, 
				@profit_percent 	float,
				@base_type 		smallint, 
				@create_flag 		smallint,
				@b_commission_amt 	float OUTPUT
AS


DECLARE	@percent_flag		float, 
		@from_bracket		float,	 
		@to_bracket 		float,	
		@com_brkamt 		float, 
		@amt_left 		float, 
		@com_sqid 		smallint,
		@last_com_sqid	smallint, 
		@amt_comm 		float, 
		@sub_comm 		float, 
		@last_brk 		float, 
		@amt_brk 		float,
		@gp_percent 		float,
		@commable_brk 	float, 
		@min_sequence_id 	smallint,
		@commissionable		float,
		@commission_amt		float,
		@commission			float,
		@bracket_commissionable	float,
		@arscomdt_sequence_id 	smallint,
		@bracket_sequence_id		smallint
		
BEGIN
	
	SELECT	@arscomdt_sequence_id = 1, 
		@b_commission_amt = 0.0

	
	IF ( @calc_type = 1 )
	BEGIN
		SELECT	@com_brkamt = NULL
	
		SELECT	@com_brkamt = commission_amt,
			@percent_flag = percent_flag,
			@from_bracket = from_bracket,
			@to_bracket = to_bracket
		FROM	arcomdet
		WHERE	commission_code = @commission_code
		 AND	to_bracket = ( SELECT	MIN( to_bracket )
					FROM	arcomdet
					WHERE	@commission_code = commission_code
					AND	ABS(@profit_percent) <= to_bracket
					AND	ABS(@profit_percent) >= from_bracket )

		
		IF ( @com_brkamt IS NULL )
		BEGIN
			
			SELECT @from_bracket = MIN( from_bracket )
			FROM arcomdet
			WHERE commission_code = @commission_code
			
			IF ((@profit_percent) < (@from_bracket) - 0.0000001)
			BEGIN
				SELECT @b_commission_amt = 0.0
				RETURN 1
			END
			ELSE
				SELECT	@com_brkamt = commission_amt,
					@percent_flag = percent_flag,
					@from_bracket = from_bracket,
					@to_bracket = to_bracket
				FROM	arcomdet
				WHERE	@commission_code = commission_code
				 AND	to_bracket = ( SELECT MAX( to_bracket )
							FROM	arcomdet
							WHERE	commission_code =
								@commission_code )
	
			IF ( @com_brkamt IS NULL )
			BEGIN
				SELECT @b_commission_amt = 0.0
				RETURN 0
			END
		END

		IF ( @percent_flag = 1 )
		BEGIN
			SELECT	@b_commission_amt = @b_commissionable * @com_brkamt / 100.0
		END
		ELSE
		BEGIN
			IF( @b_commissionable < 0.0 )
				SELECT	@b_commission_amt = @com_brkamt * -1.0
			ELSE
				SELECT @b_commission_amt = @com_brkamt
		END

		EXEC appflrnd_sp @b_commission_amt OUT

		IF @create_flag = 1
		BEGIN
			INSERT arscomdt
			(
				salesperson_code,	serial_id,			bracket_id,
				from_bracket,		to_bracket,			bracket_amt,
				percent_flag,		commissionable_amt,		commission_amt
			)
			VALUES 
			( 
				@salesperson_code,	@serial_id,			@arscomdt_sequence_id,
			 	@from_bracket,	@to_bracket,			@com_brkamt,
			 	@percent_flag,	@b_commissionable,		@b_commission_amt 
			 )
		END

		RETURN 1
	END			

	


	
	SELECT	@commissionable = ABS(@profit_percent)
	
	SELECT	@bracket_sequence_id = NULL
	SELECT	@bracket_sequence_id = MAX(sequence_id)
	FROM	arcomdet
	WHERE	commission_code = @commission_code
	AND	@commissionable >= from_bracket
	IF( @bracket_sequence_id IS NULL )
		RETURN 0
				
	WHILE(1=1)
	BEGIN
		SELECT	@commission_amt = commission_amt,
			@percent_flag = percent_flag,
			@from_bracket = from_bracket,
			@to_bracket = to_bracket
		FROM	arcomdet
		WHERE	commission_code = @commission_code
		AND	sequence_id = @bracket_sequence_id
		IF( @@rowcount = 0 )
		BEGIN
			
			BREAK		
		END

		
		SELECT	@bracket_commissionable = @commissionable - @from_bracket + 0.01

		IF( @percent_flag = 1 )
		BEGIN
			SELECT	@commission = @bracket_commissionable * @commission_amt / 100.0
			EXEC appflrnd_sp @commission OUT
		END
		ELSE
		BEGIN
			SELECT	@commission = @commission_amt
		END

		IF( @profit_percent < 0.0 )
			SELECT	@commission = -1.0 * @commission
			
				
		IF @create_flag = 1
		BEGIN
			INSERT	arscomdt
			(
				salesperson_code,	serial_id,			bracket_id,
				from_bracket,		to_bracket,			bracket_amt,
				percent_flag,		commissionable_amt,		commission_amt
			)
			VALUES	
			( 
				@salesperson_code,	@serial_id,	 		@arscomdt_sequence_id,
			 	@from_bracket,	@to_bracket,	 		@commission_amt,
			 	@percent_flag,	@bracket_commissionable,	@commission
			)

			SELECT	@arscomdt_sequence_id = @arscomdt_sequence_id + 1
		END

		
		SELECT	@commissionable = @commissionable - @bracket_commissionable

		
		SELECT	@b_commission_amt = @b_commission_amt + @commission
						
		
		IF( @bracket_sequence_id = 1 )
			BREAK
			
		SELECT	@bracket_sequence_id = @bracket_sequence_id - 1
	END

	RETURN 1
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcombrk_sp] TO [public]
GO
