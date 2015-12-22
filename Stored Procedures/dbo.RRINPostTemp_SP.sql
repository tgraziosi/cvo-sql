SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[RRINPostTemp_SP]	@all_date_flag		smallint = 1,
				@date_from		int,
				@date_end		int,
				@all_cust_flag		smallint = 1,
				@cust_from		varchar(8),
				@cust_end		varchar(8),
				@all_trx_flag		smallint = 1,
				@trx_from		varchar(16),
				@trx_end		varchar(16),
				@all_batch_flag		smallint = 1,
				@batch_from		varchar(16),
				@batch_end		varchar( 16 ),
				@hold_flag		smallint,
				@process_ctrl_num	varchar( 16 ),
				@debug_level		smallint = 0,
				@apply_date_flag	smallint = 0,
				@date_applied		int = 0

AS
















DECLARE
 @perf_time_last datetime

SELECT @perf_time_last = GETDATE()



	DECLARE	@trx_num			varchar( 16 ), 
		@trx_type 			smallint, 
		@journal_ctrl_num 		varchar( 16 ),
		@cust_code 			varchar( 8 ),
		@amt_paid 			float,	
		@last_trx_ctrl 		varchar( 16 ), 
		@result 			int, 
		@min_trx_ctrl_num		varchar( 16),
		@system_date			int,
		@tran_started		smallint,	
		@where_clause		varchar(255),
		@batch_proc_flag	smallint	
	DECLARE @next_trx_ctrl_num	VARCHAR(16)
	DECLARE @rowcount		INT
	DECLARE @customer_code		VARCHAR(8)
	DECLARE	@ship_to_code		VARCHAR(8)
	DECLARE	@price_code 		VARCHAR(8)
	DECLARE @salesperson_code	VARCHAR(8)
	DECLARE	@territory_code		VARCHAR(8)
	DECLARE	@amt_home		FLOAT
	DECLARE	@amt_oper		FLOAT
	DECLARE @home_precision		SMALLINT
	DECLARE @oper_precision		SMALLINT

	--
	-- RDS 11/24/2002
	--	MR/eFO Interface
	--	Variables for the interface
	--
	DECLARE @id			VARCHAR(40)
	DECLARE @sequence_id		INT
	DECLARE @contract_ctrl_num	VARCHAR(16)
	DECLARE @contract_sequence_id	INT
	DECLARE @source_trx_ctrl_num	VARCHAR(16)
	DECLARE @source_sequence_id	INT
	DECLARE	@source_customer_code	VARCHAR(8)
	DECLARE @source_doc_ctrl_num	VARCHAR(16)
	DECLARE @source_order_ctrl_num	VARCHAR(16)
	DECLARE @source_order_no	INT
	DECLARE @source_ext		INT
	DECLARE @svc_agreement_id	VARCHAR(100)
	DECLARE @ix			INT
	DECLARE @end_date		VARCHAR(30)
	DECLARE @data			VARCHAR(255)

	SELECT @perf_time_last = GETDATE()


	BEGIN
		IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "

		EXEC appdate_sp @system_date OUTPUT


		SELECT @batch_proc_flag = batch_proc_flag FROM arco		

		SELECT @where_clause = " WHERE trx_type = 2998 AND hold_flag = 0 AND printed_flag = 1 "
		IF @all_date_flag = 0
			SELECT @where_clause = @where_clause + " AND date_doc between " + @date_from + " and " + @date_end 
		IF @all_cust_flag = 0
			SELECT @where_clause = @where_clause + " AND customer_code between '" + @cust_from + "' and '" + @cust_end + "' " 
		IF @all_trx_flag = 0
			SELECT @where_clause = @where_clause + " AND doc_ctrl_num between '" + @trx_from + "' and '" + @trx_end + "' " 
		IF @all_batch_flag = 0
			SELECT @where_clause = @where_clause + " AND customer_code between '" + @batch_from + "' and '" + @batch_end + "' " 

			
		CREATE TABLE #trx
		(
			trx_ctrl_num	varchar(16)
		)

		EXEC (" INSERT #trx " +
			" SELECT trx_ctrl_num FROM arinpchg " + @where_clause ) 

		IF ( @@trancount = 0 )
		BEGIN
			BEGIN TRANSACTION
		END

	




		IF @batch_proc_flag = 0
			UPDATE	arinpchg
			SET	source_trx_ctrl_num = #trx.trx_ctrl_num,
				source_trx_type = 2998,
				trx_type = 2031,
				posted_flag = 0,
				process_group_num = @process_ctrl_num,
				hold_flag = @hold_flag,
				batch_code = ''			
			FROM	#trx, arinpchg
			WHERE	#trx.trx_ctrl_num = arinpchg.trx_ctrl_num
		ELSE
			UPDATE	arinpchg
			SET	source_trx_ctrl_num = #trx.trx_ctrl_num,
				source_trx_type = 2998,
				trx_type = 2031,
				posted_flag = 0,
				process_group_num = @process_ctrl_num,
				hold_flag = @hold_flag
			FROM	#trx, arinpchg
			WHERE	#trx.trx_ctrl_num = arinpchg.trx_ctrl_num
			


		IF( @@error != 0 )
			BEGIN
				ROLLBACK TRAN
				IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 139, 5 ) + " -- EXIT: "
				RETURN 34563
			END


	


		UPDATE	arinpcdt
		SET	trx_type = 2031
		FROM	#trx, arinpcdt
		WHERE	#trx.trx_ctrl_num = arinpcdt.trx_ctrl_num
		IF( @@error != 0 )
			BEGIN
				ROLLBACK TRAN
				IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 154, 5 ) + " -- EXIT: "
				RETURN 34563
			END

	


		UPDATE	arinpage
		SET	trx_type = 2031
		FROM	#trx, arinpage
		WHERE	#trx.trx_ctrl_num = arinpage.trx_ctrl_num
		IF( @@error != 0 )
			BEGIN
				ROLLBACK TRAN
				IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 168, 5 ) + " -- EXIT: "
				RETURN 34563
			END	

	


		UPDATE	arinpcom
		SET	trx_type = 2031
		FROM	#trx, arinpcom
		WHERE	#trx.trx_ctrl_num = arinpcom.trx_ctrl_num
		IF( @@error != 0 )
			BEGIN
				ROLLBACK TRAN
				IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 182, 5 ) + " -- EXIT: "
				RETURN 34563
			END	

	


		UPDATE	arinptax
		SET	trx_type = 2031
		FROM	#trx, arinptax
		WHERE	#trx.trx_ctrl_num = arinptax.trx_ctrl_num
		IF( @@error != 0 )
			BEGIN
				ROLLBACK TRAN
				IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 196, 5 ) + " -- EXIT: "
				RETURN 34563
			END	

	


		IF @apply_date_flag = 1
			BEGIN
				UPDATE	arinpchg
				SET	date_applied = @date_applied
				FROM	#trx, arinpchg
				WHERE	#trx.trx_ctrl_num = arinpchg.trx_ctrl_num
				IF( @@error != 0 )
					BEGIN
						ROLLBACK TRAN
						IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 212, 5 ) + " -- EXIT: "
						RETURN 34563
					END	

				UPDATE	arinpage
				SET	date_applied = @date_applied
				FROM	#trx, arinpage
				WHERE	#trx.trx_ctrl_num = arinpage.trx_ctrl_num
				IF( @@error != 0 )
					BEGIN
						ROLLBACK TRAN
						IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 223, 5 ) + " -- EXIT: "
						RETURN 34563
					END	
			END
	



	












	
		
	









		SELECT	@home_precision = curr_precision
		 FROM	glco, glcurr_vw
		 WHERE	glco.home_currency = glcurr_vw.currency_code

		SELECT	@oper_precision = curr_precision
		 FROM	glco, glcurr_vw
		 WHERE	glco.oper_currency = glcurr_vw.currency_code


		SELECT @next_trx_ctrl_num = ''
		WHILE (42=42)
		BEGIN
			SET ROWCOUNT 1
			SELECT @next_trx_ctrl_num = trx_ctrl_num
			 FROM #trx
			 WHERE trx_ctrl_num > @next_trx_ctrl_num
			 ORDER BY trx_ctrl_num
			SELECT @rowcount = @@rowcount
			SET ROWCOUNT 0

			IF @rowcount = 0
			BEGIN
				BREAK
			END

			SELECT @customer_code = customer_code, @ship_to_code = ship_to_code, @price_code = price_code,
				@salesperson_code = salesperson_code, @territory_code = territory_code, 
				@amt_home = ROUND(( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) * amt_net,@home_precision), 
				@amt_oper = ROUND(( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) * amt_net,@oper_precision)
			 FROM arinpchg
			 WHERE	trx_ctrl_num = @next_trx_ctrl_num

			EXEC @result = aractinp_sp @customer_code, @ship_to_code, @price_code,
						 @salesperson_code, @territory_code, @amt_home, @amt_oper, 2000			

		END






		--
		-- RDS 11/24/2002
		--	MR/eFO Interface
		--	If EAI is active, see if we can find the the service agreement id for each of the 
		--	details in this invoice and update request EAI to update the expiration date of the
		--	service agreement in eFO.
		--
		IF EXISTS( SELECT * FROM config  WHERE 	flag = 'EAI' AND value_str LIKE 'Y%') AND	--EAI enabled
		   EXISTS( SELECT * FROM config  WHERE 	flag = 'EAI_MR_EFO' AND value_str LIKE 'Y%') 	--MR/eFO interface enabled
		BEGIN

			SELECT @id = REPLACE(NEWID(),'-','')

			INSERT INTO rr_sa_update (id, trx_ctrl_num, sequence_id, contract_ctrl_num, 
						    contract_sequence_id, contract_end_date, source_doc_ctrl_num,
						    source_customer_code, source_sequence_id, source_trx_ctrl_num, 
						    source_order_ctrl_num,source_order_no, source_ext, 
						    svc_agreement_id, eai_flag)
			SELECT @id, t.trx_ctrl_num, d.sequence_id, '', 0, '', '', '', 0, '', '', 0, 0, '', -1
			  FROM #trx t, arinpcdt d
			 WHERE t.trx_ctrl_num = d.trx_ctrl_num

			-- ***TODO - Check with Paula on linkage back to original invoice
			--
			-- Get the contract number from RRMRINFO for this detail
			--
			UPDATE rr_sa_update
			   SET contract_ctrl_num = r.source_ctrl_num,
			       contract_sequence_id = r.sequence_id,
			       source_customer_code = r.customer_code,
			       contract_end_date = DATEADD(dd, r.date_maint_end - 639906, '1/1/1753')
			  FROM rrmrinfo r, rr_sa_update u
			 WHERE r.pf_inv_ctrl_num = u.trx_ctrl_num
			   AND r.inv_sequence_id = u.sequence_id

			--
			-- Get the source invoice number and sequence id from the contract
			--
			UPDATE rr_sa_update
			   SET source_doc_ctrl_num = r.invoice_ctrl_num,
			       source_sequence_id = r.source_sequence_id
			  FROM rrctrdet r, rr_sa_update u
			 WHERE r.contract_ctrl_num = u.contract_ctrl_num
			   AND r.sequence_id = u.contract_sequence_id

			--
			-- Get the source transaction number from ARTRXCDT
			-- Get order number from ARTRX and parse it (order_no-ext)
			--
			UPDATE rr_sa_update
			   SET source_trx_ctrl_num = h.trx_ctrl_num,
			       source_order_ctrl_num = h.order_ctrl_num
			  FROM artrx h, artrxcdt d, rr_sa_update u
			 WHERE h.customer_code = u.source_customer_code
			   AND d.doc_ctrl_num = u.source_doc_ctrl_num
			   AND d.sequence_id = u.source_sequence_id
			   AND d.trx_ctrl_num = h.trx_ctrl_num
			   AND d.trx_type = 2031


			UPDATE rr_sa_update
			   SET source_order_no = CAST(SUBSTRING(source_order_ctrl_num,1,CHARINDEX('-',source_order_ctrl_num)-1) AS INT),
			       source_ext = CAST(SUBSTRING(source_order_ctrl_num,CHARINDEX('-',source_order_ctrl_num)+1,DATALENGTH(RTRIM(LTRIM(source_order_ctrl_num)))) AS INT)
			 WHERE CHARINDEX('-',source_order_ctrl_num) > 1
			   AND CHARINDEX('-',source_order_ctrl_num) < DATALENGTH(RTRIM(LTRIM(source_order_ctrl_num)))

			--
			-- Get eFO Service Agreement ID from EAI_svc_agr_xref
			--
			UPDATE rr_sa_update
			   SET svc_agreement_id = r.FO_svc_agr_id,
			       eai_flag = 0
			  FROM EAI_svc_agr_xref r, rr_sa_update u
			 WHERE r.order_no = u.source_order_no
			   AND r.order_ext = u.source_ext
			   AND r.line_no = u.source_sequence_id

			--
			-- Fire off EAI request
			--

			EXEC EAI_process_insert 'SARequest', @id, 'BO' 

		
			UPDATE arinpchg
			   SET order_ctrl_num = u.source_order_ctrl_num
			  FROM arinpcdt r, rr_sa_update u
			 WHERE r.trx_ctrl_num = u.trx_ctrl_num
			   AND r.trx_type = 2031
		END


		COMMIT TRANSACTION









	IF ( @debug_level > 9 ) SELECT CONVERT(char,getdate(),109) + "  " + "rrinpt.sp" + ", line " + STR( 317, 5 ) + " -- EXIT: "
	RETURN 0 
END

GO
GRANT EXECUTE ON  [dbo].[RRINPostTemp_SP] TO [public]
GO
