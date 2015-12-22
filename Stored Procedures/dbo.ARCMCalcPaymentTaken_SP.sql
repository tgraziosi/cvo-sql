SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCalcPaymentTaken_SP]	@apply_to_num		varchar( 16 ),
						@apply_trx_type	smallint,
						@amt_gross		float,
						@amt_discount_given	float,
						@amt_freight		float,
						@amt_tax		float
AS

DECLARE
	@amt_net				float,
	@amt_write_off_given			float,
	@amt_disc_taken			float,	
	@amt_write_off_returned		float,
	@amt_disc_taken_returned		float,
	@amt_discount_taken_return		float,
	@amt_write_off_return		float
	
BEGIN
	
	SELECT	@amt_write_off_given = 0.0,
		@amt_disc_taken = 0.0,
		@amt_write_off_returned = 0.0,
		@amt_disc_taken_returned = 0.0
	
	SELECT	@amt_net = @amt_gross + @amt_tax + @amt_freight - @amt_discount_given

	
	SELECT	@amt_write_off_given = ISNULL(artrx.amt_write_off_given, 0.0),
		@amt_disc_taken = ISNULL(artrx.amt_discount_taken, 0.0)
	FROM	artrx
	WHERE	artrx.doc_ctrl_num = @apply_to_num
	AND	artrx.trx_type = @apply_trx_type

	
	SELECT	@amt_write_off_returned = 0.0,
		@amt_disc_taken_returned = 0.0

	
	IF( @amt_write_off_given - @amt_write_off_returned < @amt_net )
	BEGIN
		SELECT	@amt_write_off_return = @amt_write_off_given - @amt_write_off_returned

		
		SELECT	@amt_net = @amt_net - @amt_write_off_return						
		
		IF( @amt_disc_taken - @amt_disc_taken_returned < @amt_net )
			SELECT	@amt_discount_taken_return = @amt_disc_taken - @amt_disc_taken_returned
		ELSE
			SELECT	@amt_discount_taken_return = @amt_net
	END
	ELSE
	BEGIN
		
		SELECT	@amt_write_off_return = @amt_net,
			@amt_discount_taken_return = 0.0
	END
	
	
	SELECT	@amt_write_off_return,
		@amt_discount_taken_return	
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCalcPaymentTaken_SP] TO [public]
GO
