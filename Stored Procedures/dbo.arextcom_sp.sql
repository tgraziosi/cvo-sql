SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
			
CREATE PROC [dbo].[arextcom_sp]	@salesperson_code	varchar(8),	
				@doc_ctrl_num 	varchar(16),
				@trx_type 		smallint,	
				@calc_type 		smallint,
				@table_type 		smallint, 
				@base_type 		smallint,
				@commission_code	varchar(8),
				@customer_name	varchar(40),
				@amt_invoice 		float,	
				@amt_cost 		float,
				@date_used 		int,	
				@date_comm 		int,	
				@doc_date 		int,
				@user_id 		smallint,	
				@date_from 		int,
				@date_thru 		int,	
				@cust_code 		varchar(8)
AS

DECLARE	
	@net_comm			float,		
	@perc_flag 			smallint,
	@seq_id 			int, 	
	@last_sqid 			int, 	
	@split_flag 			smallint,	
	@qty_shipped 			float,	
	@status 			smallint,	
	@override_salesperson 	varchar(8),
	@amt_comm 			float,
	@override_commission_code 	varchar(8),	
	@e_seqid 			int,
	@negflag			smallint

BEGIN
	SELECT	@status = 1

	IF @trx_type = 2032
		SELECT @negflag = -1
	ELSE	
		SELECT	@negflag = 1
	
	SELECT	@seq_id = -1
	
	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_sqid = @seq_id
	
		SELECT	@seq_id = NULL
	
		SET	ROWCOUNT 1
	
		SELECT	@seq_id = sequence_id,
			@override_salesperson = salesperson_code,
			@amt_comm = amt_commission,
			@perc_flag = percent_flag,
			@split_flag = split_flag
		FROM	artrxcom
		WHERE	trx_type = @trx_type
		 AND	doc_ctrl_num = @doc_ctrl_num
		 AND	commission_flag = 0
		 AND	sequence_id > @last_sqid
	
		SET	ROWCOUNT 0
	
		IF ( @seq_id IS NULL )
			BREAK

		
		SELECT	@base_type = NULL

		SELECT	@base_type = m.base_type,
			@table_type = m.table_amt_type,
			@calc_type = m.calc_type,
			@override_commission_code = m.commission_code 
		FROM	arsalesp s, arcomm m
		WHERE	s.commission_code = m.commission_code
		AND	s.salesperson_code = @override_salesperson
	
		IF @base_type IS NULL
			RETURN 0
		
		
		IF ( @split_flag = 0 ) 
		BEGIN
			IF ( @perc_flag = 1 )
				SELECT	@net_comm = (SIGN((@amt_invoice * @amt_comm / 100.0)) * ROUND(ABS((@amt_invoice * @amt_comm / 100.0)) + 0.0000001, 6))
			ELSE
				SELECT	@net_comm = (SIGN(@amt_comm) * ROUND(ABS(@amt_comm) + 0.0000001, 6))
			
			SELECT	@e_seqid = NULL
			SELECT	@e_seqid = MAX( serial_id )
			FROM	arsalcom
			WHERE	salesperson_code = @override_salesperson

			IF @e_seqid IS NULL
				SELECT @e_seqid = 1
			ELSE
				SELECT @e_seqid = @e_seqid + 1

			INSERT	arsalcom
			(	
				salesperson_code,		customer_code,	comm_type,	 	
				serial_id,			doc_ctrl_num,		trx_type,
				doc_date,			description,		commission_code, 	
				doc_amt,			amt_cost,	 	commissionable_amt,
				commissionable,		commission_adjust,	net_commission,	 	
				date_used,			user_id,	 	date_commission,
				base_type, 			table_amt_type 
			)
			VALUES
			(	
				@override_salesperson, @cust_code,		1,			
				@e_seqid, 			@doc_ctrl_num,	@trx_type,
				@doc_date,			@customer_name, 	@override_commission_code,		
				@amt_invoice,			0.0,			0.0,
				@amt_invoice,			@net_comm * @negflag,@net_comm * @negflag,		
				@date_used,			@user_id,		@date_comm,
				@base_type,			@table_type 
			)

			UPDATE	artrxcom
			SET	commission_flag = 2
			WHERE	doc_ctrl_num = @doc_ctrl_num
			AND	trx_type = @trx_type
			AND	sequence_id = @seq_id

			CONTINUE
		END

		
		
		IF @table_type IN ( 1, 2 )
			EXEC @status = arcominv_sp	@trx_type, 
							@doc_ctrl_num, 
							@override_salesperson, 
							@date_used,
							@base_type, 
							@calc_type, 
							@override_commission_code, 
							@amt_invoice, 
							@amt_cost, 
							@date_comm, 
							@amt_comm, 
							@customer_name,
							@doc_date, 
							@user_id, 
							@date_from,
							@date_thru, 
							@cust_code,
							@table_type

		
		ELSE IF ( @table_type = 0 )
		BEGIN
			EXEC @status = arcomlin_sp	@trx_type, 
							@doc_ctrl_num, 
							@override_salesperson, 
							@date_used, 
							@date_comm, 
							@amt_comm, 
							@doc_date, 
							@user_id, 
							@date_from, 
							@date_thru,
							@cust_code,	
							@table_type
		END
		ELSE
			RETURN 0

		IF @status = 0
			RETURN @status

	END		

	RETURN 1
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arextcom_sp] TO [public]
GO
