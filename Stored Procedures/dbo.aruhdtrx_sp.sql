SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[aruhdtrx_sp]	
AS


DECLARE	@customer_code	varchar(8),	
		@ship_to_code		varchar(8),	
		@price_code		varchar(8), 	
		@salesperson_code	varchar(8),
		@territory_code	varchar(8),
		@amt_home 		float, 
		@amt_oper		float,
		@hold_flag		smallint,
		@trx_ctrl_num		varchar(16), 
		@trx_type		smallint,
		@home_precision	smallint,
		@oper_precision	smallint
		
SELECT @home_precision = h.curr_precision,
	@oper_precision = o.curr_precision
FROM	glco, glcurr_vw h, glcurr_vw o
WHERE	home_currency = h.currency_code
AND	oper_currency = o.currency_code	

SELECT @trx_ctrl_num = ''
SET ROWCOUNT 1
BEGIN TRAN

	
	WHILE ( 1 = 1 )
	BEGIN
		
		SELECT	@trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#arvalchg
		WHERE	trx_ctrl_num > @trx_ctrl_num
	 
		SELECT	@trx_type = trx_type,
				@hold_flag = hold_flag
		FROM	#arvalchg
		WHERE	trx_ctrl_num = @trx_ctrl_num

		
		IF ( @@rowcount = 0 )
		BEGIN
			SET ROWCOUNT 0
			COMMIT TRAN
			RETURN
		END

		
		IF ( @hold_flag = 1 )
			CONTINUE


			
		SELECT	@customer_code = customer_code,
			@ship_to_code = ship_to_code,
			@price_code = price_code,
			@salesperson_code = salesperson_code,
			@territory_code = territory_code,
			@amt_home = ROUND(amt_due * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @home_precision),	
			@amt_oper = ROUND(amt_due * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @oper_precision)	
		FROM 	arinpchg
		WHERE	trx_ctrl_num = @trx_ctrl_num 
 
		UPDATE	arinpchg
		SET	hold_flag = 0,
			hold_desc = SPACE(1)
		WHERE	trx_ctrl_num = @trx_ctrl_num 
 
		
		EXEC	aractinp_sp	@customer_code, 
					@ship_to_code, 
					@price_code,
					@salesperson_code, 
					@territory_code, 
					@amt_home,
					@amt_oper,
					2000	

		DELETE	#arvalchg
		WHERE	trx_ctrl_num = @trx_ctrl_num
	END 
 
GO
GRANT EXECUTE ON  [dbo].[aruhdtrx_sp] TO [public]
GO
