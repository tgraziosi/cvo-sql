SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcomlin_sp]	@trx_type		smallint,	
				@doc_ctrl_num		varchar(16),	
				@salesperson_code	varchar(8), 	
				@date_used		int,
				@date_commission	int,
				@commission_percent	float,	
				@doc_date		int,	
				@user_id		smallint,
				@date_from		int,	
				@date_thru		int,
				@customer_code	varchar(8), 
				@table_type 		smallint
AS

DECLARE	@ext_amt		float,		
		@commissionable	float,
		@exclude_flag 	smallint,	
		@last_sqid 		int,
		@l_comm_amt 		float,	
		@profit_perc 		float,
		@seq_id 		int,		
		@item_code 		varchar(30),
		@bulk_flag 		smallint,	
		@loc_code 		varchar(8),
		@qty_shipped 		float,	
		@unit_price 		float,
		@line_desc 		varchar(60), 
		@negflag 		smallint,
		@adj_base_amt 	float,	
		@override_amt 	float,
		@amt_cost 		float,	
		@status 		int,
		@l_sqid 		int,		
		@unit_code 		varchar(8),
		@gross_sale 		float,	
		@gross_cost 		float

DECLARE
				@base_type 		smallint,	
				@calc_type 		smallint,
				@commission_code 	varchar(8),
				@curr_precision	smallint
BEGIN	
	
	SELECT	@l_comm_amt = 0.0, 
		@seq_id = -1, 
		@gross_cost = 0.0, 
		@gross_sale = 0.0

	
	SELECT	@curr_precision = curr_precision
	FROM	glco, glcurr_vw
	WHERE	glco.home_currency = glcurr_vw.currency_code

	IF @trx_type = 2032
		SELECT @negflag = -1
	ELSE	
		SELECT @negflag = 1

	WHILE ( 1 = 1 )
	BEGIN
		
		SELECT	@last_sqid = @seq_id,
			@l_comm_amt = 0.0,
			@seq_id = NULL, @exclude_flag = 0

		SET	ROWCOUNT 1
		IF( @trx_type = 2032 )
		BEGIN
			SELECT	@seq_id = sequence_id,
				@item_code = item_code,
				@bulk_flag = bulk_flag,
				@loc_code = location_code,
				@qty_shipped = qty_shipped,
				@unit_price = unit_price,
				@line_desc = line_desc,
				@unit_code = unit_code,
				@amt_cost = artrxcdt.amt_cost * @commission_percent / 100.0,
				@ext_amt = ROUND(( SIGN(1 + SIGN(artrx.rate_home))*(artrx.rate_home) + (SIGN(ABS(SIGN(ROUND(artrx.rate_home,6))))/(artrx.rate_home + SIGN(1 - ABS(SIGN(ROUND(artrx.rate_home,6)))))) * SIGN(SIGN(artrx.rate_home) - 1) ) * (unit_price * qty_returned - discount_amt) * @commission_percent/100.0, @curr_precision),
				@base_type = arcomm.base_type,
				@calc_type = arcomm.calc_type,
				@commission_code = arsalesp.commission_code
			FROM	artrxcdt, arsalesp, arcomm, artrx
			WHERE	artrxcdt.doc_ctrl_num = @doc_ctrl_num
			AND	sequence_id > @last_sqid
			AND	arcomm.commission_code = arsalesp.commission_code
			AND	arsalesp.salesperson_code = @salesperson_code
			AND	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
			AND	artrxcdt.trx_type = artrx.trx_type
			ORDER BY sequence_id
		END
		ELSE
		BEGIN
			SELECT	@seq_id = sequence_id,
				@item_code = item_code,
				@bulk_flag = bulk_flag,
				@loc_code = location_code,
				@qty_shipped = qty_shipped,
				@unit_price = unit_price,
				@line_desc = line_desc,
				@unit_code = unit_code,
				@amt_cost = artrxcdt.amt_cost * @commission_percent / 100.0,
				@ext_amt = ROUND(( SIGN(1 + SIGN(artrx.rate_home))*(artrx.rate_home) + (SIGN(ABS(SIGN(ROUND(artrx.rate_home,6))))/(artrx.rate_home + SIGN(1 - ABS(SIGN(ROUND(artrx.rate_home,6)))))) * SIGN(SIGN(artrx.rate_home) - 1) ) * ( unit_price * qty_shipped - discount_amt ) * @commission_percent/100.0, @curr_precision),
				@base_type = arcomm.base_type,
				@calc_type = arcomm.calc_type,
				@commission_code = arsalesp.commission_code
			FROM	artrxcdt, arsalesp, arcomm, artrx
			WHERE	artrxcdt.doc_ctrl_num = @doc_ctrl_num
			AND	sequence_id > @last_sqid
			AND	arcomm.commission_code = arsalesp.commission_code
			AND	arsalesp.salesperson_code = @salesperson_code
			AND	artrx.trx_ctrl_num = artrxcdt.trx_ctrl_num
			AND	artrx.trx_type = artrxcdt.trx_type
			ORDER BY sequence_id
		END
		
		SET	ROWCOUNT 0

		IF @seq_id IS NULL
			BREAK

		
		IF ((@ext_amt) <= (0.0) + 0.0000001) 
			CONTINUE

		
		IF @base_type = 0 
			SELECT	@commissionable = @ext_amt
		ELSE IF @base_type IN ( 1, 2 )
			SELECT	@commissionable = @ext_amt - @amt_cost 
		ELSE 
			RETURN 0
	
		IF @base_type = 2 
			SELECT	@profit_perc = @commissionable/@ext_amt * 100
		ELSE
			SELECT	@profit_perc = @commissionable

		SELECT	@gross_sale = @gross_sale + @ext_amt,
			@gross_cost = @gross_cost + @amt_cost

		


			
	
		SELECT	@l_sqid = ISNULL(MAX( serial_id ), 0) + 1
		FROM	arsalcom
		WHERE	salesperson_code = @salesperson_code

		

			EXEC @status = arcombrk_sp	@salesperson_code, 
							@l_sqid, 
		 			 		@calc_type, 
		 			 		@commission_code, 
					 		@commissionable, 
					 		@profit_perc,
					 		@base_type, 
					 		1, 
					 		@l_comm_amt OUT
			IF @status = 0
				RETURN @status


		SELECT	@commissionable = @commissionable * @negflag,
			@l_comm_amt = @l_comm_amt * @negflag,
			@ext_amt = @ext_amt * @negflag

		INSERT	arsalcom 
		(
			salesperson_code,	customer_code,			comm_type,	 	
			serial_id,		doc_ctrl_num,				trx_type,
			doc_date,		description,				commission_code, 	
			doc_amt,		amt_cost,	 			commissionable_amt,
			commissionable,	commission_adjust,			net_commission,	 	
			date_used,		user_id,	 			date_commission,
			base_type, 		table_amt_type 
		)
		VALUES
		(	
			@salesperson_code,	@customer_code,			1,			
			@l_sqid, 		@doc_ctrl_num,			@trx_type,
			@doc_date,		@line_desc,				@commission_code, 	
			@ext_amt,		@amt_cost,				@commissionable,
			@profit_perc,		0.0,					@l_comm_amt,	 
			@date_used, 		@user_id,				@date_commission,
			@base_type,		@table_type 
		)
	END	


	RETURN 1
END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcomlin_sp] TO [public]
GO
