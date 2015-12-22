SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcomtol_sp] @user_id smallint
AS
DECLARE	@last_salesperson_code 	varchar(8), 
		@salesperson_code 		varchar( 8 ),
		@commissionable 		float, 
		@comm_adj 			float,
		@table_type 			smallint, 
		@comm_code 			varchar( 8 ),
		@seqid 			int, 
		@status 			smallint,
		@calc_type 			smallint, 
		@doc_ctrl_num 		varchar( 16 ),
		@comm_amt 			float, 
		@trx_type 			smallint,
		@last_doc_ctrl_num 		varchar( 16 ), 
		@base_type 			smallint,
		@gross_perc 			float, 
		@gross_cost 			float, 
		@gross_sale 			float
BEGIN
	SELECT	@salesperson_code = ' ',
		@status = 1

	WHILE ( 1 = 1 )
	BEGIN
		SELECT	@last_salesperson_code = @salesperson_code
		
		SELECT	@salesperson_code = NULL
	
		SELECT	@salesperson_code = MIN( salesperson_code )
		FROM	arsalcom
		WHERE	salesperson_code > @last_salesperson_code
	
		IF @salesperson_code IS NULL
			BREAK
		
		SELECT	@table_type = b.table_amt_type,
			@calc_type = b.calc_type,
			@base_type = b.base_type,
			@comm_code = b.commission_code
		FROM	arsalesp a, arcomm b
		WHERE	a.salesperson_code = @salesperson_code
		AND	a.commission_code = b.commission_code
	
		SELECT	@seqid = NULL
	
		SELECT	@seqid = MAX( serial_id ) + 1
		FROM	arsalcom
		WHERE	salesperson_code = @salesperson_code
	
		IF @seqid IS NULL
			SELECT @seqid = 1
		ELSE
			SELECT @seqid = @seqid + 1
	
		
		IF @table_type = 2
		BEGIN
			SELECT @commissionable = NULL
			SELECT @commissionable = SUM( commissionable_amt ),
				@comm_adj = SUM( commission_adjust ),
				@gross_sale = SUM( doc_amt ),
				@gross_cost = SUM(amt_cost)
			FROM	arsalcom
			WHERE	salesperson_code = @salesperson_code
			AND	comm_type = 1 
	
			IF @commissionable IS NULL
				CONTINUE
			
			IF @base_type = 2
			BEGIN
				
				IF( @gross_sale = 0.0 )
					SELECT	@gross_perc = 0.0
				ELSE
					SELECT	@gross_perc = 1.0 - (@commissionable / @gross_sale * 100)
			END
			ELSE
			BEGIN
				
				SELECT @gross_perc = @commissionable
			END

			EXEC @status = arcombrk_sp	@salesperson_code, 
							@seqid,
			 				@calc_type, 
			 				@comm_code, 	
			 				@commissionable, 
			 				@gross_perc, 
			 				@base_type, 	
			 				1, 
			 				@comm_amt OUT

				
			SELECT @doc_ctrl_num = MAX( doc_ctrl_num )
			FROM arsalcom
			WHERE salesperson_code = @salesperson_code	

			INSERT	arsalcom 
			(
				salesperson_code,	customer_code,	comm_type,	 	
				serial_id,		doc_ctrl_num,		trx_type,
				doc_date,		description,		commission_code, 	
				doc_amt,		amt_cost,	 	commissionable_amt,
				commissionable,	commission_adjust,	net_commission,	 	
				date_used,		user_id,	 	date_commission,
				base_type, 		table_amt_type 
			)
			VALUES
			(	
				@salesperson_code,	" ",			2,			
				@seqid,		@doc_ctrl_num,	0,
				0,			" ",	 	@comm_code,		
				@gross_sale,		@gross_cost,		@commissionable,
				@gross_perc,		@comm_adj,		@comm_amt + @comm_adj, 
				0,			@user_id,		0,
				@base_type,		@table_type 
			)
			CONTINUE
		END
		ELSE IF @table_type = 1
		BEGIN
			
			SELECT @doc_ctrl_num = ' '
	
			WHILE ( 1 = 1 )
			BEGIN
				SELECT @last_doc_ctrl_num = @doc_ctrl_num
	
				SELECT @doc_ctrl_num = NULL
	
				SET ROWCOUNT 1
				SELECT	@doc_ctrl_num = MIN(doc_ctrl_num)
				FROM	arsalcom
				WHERE	salesperson_code = @salesperson_code
				AND	comm_type = 1
				AND	doc_ctrl_num > @last_doc_ctrl_num
					
				SET ROWCOUNT 0
				IF @doc_ctrl_num IS NULL
					BREAK

				SELECT	@gross_sale = SUM(doc_amt),
					@gross_cost = SUM(amt_cost),
					@commissionable = SUM(commissionable_amt),
					@comm_adj = SUM(commission_adjust),
					@trx_type = trx_type
				FROM	arsalcom
				WHERE	doc_ctrl_num = @doc_ctrl_num
				AND	comm_type = 1
				AND	salesperson_code = @salesperson_code
				GROUP BY doc_ctrl_num, trx_type

				IF @base_type = 2
				BEGIN

					
					IF( @gross_sale = 0.0 )
						SELECT	@gross_perc = 0.0
					ELSE
						SELECT	@gross_perc = @commissionable / @gross_sale * 100
				END
				ELSE
					SELECT @gross_perc = @commissionable
	
				EXEC @status = arcombrk_sp	@salesperson_code, 
								@seqid,
				 			 	@calc_type, 
				 			 	@comm_code,
						 	@commissionable, 
						 	@gross_perc,
							 	@base_type, 
							 	1, 
							 	@comm_amt OUT
				INSERT	arsalcom 
				(
					salesperson_code,	customer_code,	comm_type,	 	
					serial_id,		doc_ctrl_num,		trx_type,
					doc_date,		description,		commission_code, 	
					doc_amt,		amt_cost,	 	commissionable_amt,
					commissionable,	commission_adjust,	net_commission,	 	
					date_used,		user_id,	 	date_commission,
					base_type, 		table_amt_type 
				)
				VALUES
				(	@salesperson_code,	" ",			2,		 
					@seqid,		@doc_ctrl_num, 	@trx_type,
					0,		 	" ",			@comm_code,	 
					0,			0.0,		 	@commissionable,
					@gross_perc,	 	@comm_adj,		@comm_amt + @comm_adj,	
					0, 			@user_id,	 	0,
					@base_type,	 	@table_type 
				)
	
				SELECT	@seqid = @seqid + 1
			END
	
			CONTINUE
		END
	END

	RETURN @status
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcomtol_sp] TO [public]
GO
