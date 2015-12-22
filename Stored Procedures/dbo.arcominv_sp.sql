SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcominv_sp]	@trx_type		smallint,	
				@doc_ctrl_num 	varchar(16), 
				@salesperson_code 	varchar(8),	
				@date_used 		int,
 				@base_type 		smallint,	
 				@calc_type 		smallint,
				@commission_code 	varchar(8), 	
				@amt_invoice 		float,
				@amt_cost 		float,	
				@date_comm 		int, 
				@comm_perc 		float,	
				@cust_name 		varchar(40), 
				@doc_date 		int,	
				@user_id 		smallint,
				@date_from 		int,
				@date_thru 		int,	
				@customer_code 	varchar(8),
 				@table_type		smallint
AS

DECLARE	@commissionable	float, 
		@exclude_flag 	smallint,
		@item_code 		varchar(30), 
		@loc_code 		varchar(8),
		@sequence_id 		int,
		@last_sequence_id 	int, 
		@line_amt 		float,
		@line_cost 		float, 
		@line_desc 		varchar(60),
		@negflag 		smallint, 
		@qty_shipped 		float, 
		@serial_id 		int,
		@unit_code 		varchar(8), 
		@unit_price 		float, 
		@status 		int, 
		@tot_excluded_sale 	float,
		@tot_excluded_cost 	float,
		@commissionable_amt 	float, 	
		@min_sequence_id 	int
BEGIN

	SELECT	@tot_excluded_sale = 0.0, 
		@status = 1, 
		@tot_excluded_cost = 0.0

	IF @trx_type = 2032
		SELECT @negflag = -1
	ELSE
		SELECT @negflag = 1

	
	SELECT	@sequence_id = -1

	
	
	SELECT	@amt_invoice = @negflag * ( @amt_invoice - @tot_excluded_sale ) * @comm_perc / 100,
		@amt_cost = @negflag * ( @amt_cost - @tot_excluded_cost ) * @comm_perc / 100
		
	
	IF @base_type = 0 
	BEGIN
		
		SELECT	@commissionable_amt = @amt_invoice, 
			@commissionable = @amt_invoice
	END
	ELSE IF @base_type = 1 
	BEGIN
		
		SELECT	@commissionable_amt = @amt_invoice - @amt_cost,
			@commissionable = @amt_invoice - @amt_cost
	END
	ELSE IF @base_type = 2 
	BEGIN
		
		SELECT	@commissionable_amt = @amt_invoice - @amt_cost
		IF( @amt_invoice = 0.0 )
			SELECT @commissionable = 0.0
		ELSE
			SELECT @commissionable = @commissionable_amt / @amt_invoice * 100
	END

		
	SELECT @commissionable_amt = (SIGN(@commissionable_amt) * ROUND(ABS(@commissionable_amt) + 0.0000001, 6))

	
	SELECT	@serial_id = ISNULL(MAX( serial_id ), 0) + 1 
	FROM	arsalcom
	WHERE	salesperson_code = @salesperson_code

		
	INSERT	arsalcom
	(
		salesperson_code,		customer_code,		comm_type,	 	
		serial_id,			doc_ctrl_num,			trx_type,
		doc_date,			description,			commission_code, 	
		doc_amt,			amt_cost,	 		commissionable_amt,
		commissionable,		commission_adjust,		net_commission,	 	
		date_used,			user_id,	 		date_commission,
		base_type, 			table_amt_type 
	)
	VALUES
	(
		@salesperson_code,		@customer_code,		1,			
		@serial_id,			@doc_ctrl_num,		@trx_type, 
		@doc_date,			@cust_name, 		@commission_code, 	
		@amt_invoice,			@amt_cost,			@commissionable_amt,
		@commissionable,		0.0,				0.0,			
		@date_used,			@user_id,			@date_comm,
		@base_type,			@table_type 
	)

	
	SELECT	@serial_id = @serial_id + 1
	
	
	INSERT	arsalcom
	(
		salesperson_code,			customer_code,		comm_type,	 	
		serial_id,				doc_ctrl_num,			trx_type,
		doc_date,				description,			commission_code, 	
		doc_amt,				amt_cost,	 		commissionable_amt,
		commissionable,			commission_adjust,		
		net_commission,	 		date_used,			user_id,	 		
		date_commission,			base_type, 			table_amt_type 
	)
	SELECT	arcomadj.salesperson_code,		artrx.customer_code,		1,
		@serial_id + arcomadj.sequence_id,	arcomadj.doc_ctrl_num,	artrx.trx_type,
		artrx.date_doc,			arcomadj.description,	arsalesp.commission_code,
		0.0,					0.0,				arcomadj.adj_base_amt * @negflag,
		arcomadj.adj_base_amt * @negflag,	arcomadj.adj_override_amt * @negflag,	
		0.0,					@date_used,			@user_id,			
		@date_comm,				arcomm.base_type,			arcomm.table_amt_type
	FROM	arcomadj, artrx, arsalesp, arcomm
	WHERE	arcomadj.doc_ctrl_num = artrx.doc_ctrl_num
	AND	arcomadj.salesperson_code = arsalesp.salesperson_code
	AND	arsalesp.commission_code = arcomm.commission_code
	AND	arcomadj.doc_ctrl_num = @doc_ctrl_num
	AND	arsalesp.salesperson_code = @salesperson_code
	AND	artrx.trx_type = @trx_type

	
	UPDATE	arcomadj
	SET	posted_flag = 2
	WHERE	salesperson_code = @salesperson_code
	AND	posted_flag = 0
	AND	date_effective BETWEEN @date_from AND @date_thru

	RETURN 1
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcominv_sp] TO [public]
GO
