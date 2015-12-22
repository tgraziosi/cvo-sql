SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARPYNSFActivity_SP]		@batch_ctrl_num		varchar( 16 ),
									@t_prc_flag 		smallint,	
									@t_slp_flag 		smallint,	
									@t_ter_flag 		smallint, 
									@t_shp_flag 		smallint,	
									@t_mast_flag 		smallint,	
									@t_cus_flag 		smallint,	
									@t_prc_code 		varchar( 8 ),	
									@t_slp_code 		varchar( 8 ),	
									@t_ter_code 		varchar( 8 ), 
									@t_shp_code 		varchar( 8 ),	
									@t_cus_code 		varchar( 8 ),	
									@t_trx_time 		int, 
									@t_dcn 				varchar( 16 ),	
									@t_date_applied 	int,	
									@t_amt_applied 		float,	 
									@t_period_end 		int,
									@debug_level		smallint = 0,
									@perf_level			smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result			int,
	@last_trx_time 	smallint,
	@last_pyt_doc 	varchar( 16 ), 
	@last_wr_doc 	varchar( 16 ),	
	@last_nsf_doc 	varchar( 16 ),	
	@last_wr_date 	int,	
	@last_nsf_date 	int, 
	@last_pyt_date 	int,	
	@short_time 	int, 
	@today 			int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arpynsfa.sp", 100, "ARPYNSFActivity_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arpynsfa.sp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "
	
	SELECT	@short_time = @t_trx_time % 1000

	EXEC appdate_sp @today OUTPUT

	

	
	IF ( @t_prc_flag > 0 )
	BEGIN
		SELECT	@last_nsf_doc = last_nsf_doc,
				@last_nsf_date = date_last_nsf,
				@last_trx_time = last_trx_time % 1000
		FROM	#aractprc_work
		WHERE	price_code = @t_prc_code

		IF (( @last_trx_time != @short_time ) 
		OR ( @t_dcn != @last_nsf_doc )
		OR ( @last_nsf_date != @today ))
		BEGIN 
			UPDATE	#aractprc_work
			SET		date_last_nsf = @today,
					amt_last_nsf = @t_amt_applied,
					last_nsf_doc = @t_dcn,
					last_trx_time = ( last_trx_time / 1000 ) * 1000 + @short_time
			WHERE	price_code = @t_prc_code
		END
		ELSE
		BEGIN
			UPDATE	#aractprc_work
			SET		amt_last_nsf = ISNULL(amt_last_nsf, 0.0) + @t_amt_applied
			WHERE	price_code = @t_prc_code
		END
		
				
		IF ( @t_trx_time != (	SELECT	last_trx_time
								FROM	#arsumprc_work
								WHERE	price_code = @t_prc_code
	 							 AND	date_thru = @t_period_end ))
		BEGIN
			UPDATE	#arsumprc_work
			SET		num_nsf	= ISNULL(num_nsf, 0) + 1,
					amt_nsf	= ISNULL(amt_nsf, 0.0) + @t_amt_applied,
					last_trx_time = @t_trx_time
			WHERE	price_code = @t_prc_code
		 	 AND	date_thru = @t_period_end
		END
		ELSE
		BEGIN
			UPDATE	#arsumprc_work
			SET		amt_nsf	= ISNULL(amt_nsf, 0.0) + @t_amt_applied
			WHERE	price_code = @t_prc_code
		 	 AND	date_thru = @t_period_end
		END

	END	

	
	IF (( @t_shp_flag > 0 ) AND ( @t_mast_flag > 0 ))
	BEGIN
		SELECT	@last_nsf_doc = last_nsf_doc,
				@last_nsf_date = date_last_nsf,
				@last_trx_time = last_trx_time % 1000
		FROM	#aractshp_work
		WHERE	customer_code = @t_cus_code
 		AND		ship_to_code = @t_shp_code

		IF (( @last_trx_time != @short_time ) 
		OR ( @t_dcn != @last_nsf_doc )
		OR ( @last_nsf_date != @today ))
		BEGIN
			UPDATE	#aractshp_work
			SET		date_last_nsf = @today,
					amt_last_nsf = @t_amt_applied,
					last_nsf_doc = @t_dcn,
					last_trx_time = ( last_trx_time / 1000 ) * 1000 + @short_time
			WHERE	customer_code = @t_cus_code
	 		 AND	ship_to_code = @t_shp_code
		END
		ELSE
		BEGIN
			UPDATE	#aractshp_work
			SET		amt_last_nsf = ISNULL(amt_last_nsf, 0.0) + @t_amt_applied
			WHERE	customer_code = @t_cus_code
	 		 AND	ship_to_code = @t_shp_code
		END

		IF ( @t_trx_time != (	SELECT	last_trx_time
								FROM	#arsumshp_work
								WHERE	customer_code = @t_cus_code
	 							 AND	ship_to_code = @t_shp_code 
	 							 AND	date_thru = @t_period_end ))
		BEGIN
			UPDATE	#arsumshp_work
			SET		num_nsf	= ISNULL(num_nsf, 0) + 1,
					amt_nsf	= ISNULL(amt_nsf, 0.0) + @t_amt_applied,
					last_trx_time = @t_trx_time
			WHERE	customer_code = @t_cus_code
		 	 AND	ship_to_code = @t_shp_code
		 	 AND	date_thru = @t_period_end
		END
		ELSE
		BEGIN
			UPDATE	#arsumshp_work
			SET		amt_nsf	= ISNULL(amt_nsf, 0.0) + @t_amt_applied
			WHERE	customer_code = @t_cus_code
			 AND	ship_to_code = @t_shp_code
			 AND	date_thru = @t_period_end
		END
	END	

	
	IF ( @t_slp_flag > 0 )
	BEGIN
		SELECT	@last_nsf_doc = last_nsf_doc,
				@last_nsf_date = date_last_nsf,
				@last_trx_time = last_trx_time % 1000
		FROM	#aractslp_work
		WHERE	salesperson_code = @t_slp_code

		IF (( @last_trx_time != @short_time ) 
		OR ( @t_dcn != @last_nsf_doc )
		OR ( @last_nsf_date != @today ))
		BEGIN
			UPDATE	#aractslp_work
			SET		date_last_nsf = @today,
					amt_last_nsf = @t_amt_applied,
					last_nsf_doc = @t_dcn,
					last_trx_time = ( last_trx_time / 1000 ) * 1000 + @short_time
			WHERE	salesperson_code = @t_slp_code
		END
		ELSE
		BEGIN
			UPDATE	#aractslp_work
			SET		amt_last_nsf = ISNULL(amt_last_nsf, 0.0) + @t_amt_applied
			WHERE	salesperson_code = @t_slp_code
		END


		IF ( @t_trx_time != (	SELECT last_trx_time
								FROM	#arsumslp_work
								WHERE	salesperson_code = @t_slp_code 
 		 						 AND	date_thru = @t_period_end ))
		BEGIN
			UPDATE	#arsumslp_work
			SET		num_nsf	= ISNULL(num_nsf, 0) + 1,
					amt_nsf	= ISNULL(amt_nsf, 0) + @t_amt_applied,
					last_trx_time = @t_trx_time
			WHERE	salesperson_code = @t_slp_code
	 		 AND	date_thru = @t_period_end
		END
		ELSE
		BEGIN
			UPDATE	#arsumslp_work
			SET		amt_nsf	= ISNULL(amt_nsf, 0.0) + @t_amt_applied
			WHERE	salesperson_code = @t_slp_code
		 	 AND	date_thru = @t_period_end
		END
	END 

	
	IF ( @t_ter_flag > 0 )
	BEGIN
		SELECT	@last_nsf_doc = last_nsf_doc,
				@last_nsf_date = date_last_nsf,
				@last_trx_time = last_trx_time % 1000
		FROM	#aractter_work
		WHERE	territory_code = @t_ter_code

		IF (( @last_trx_time != @short_time ) 
		OR ( @t_dcn != @last_nsf_doc )
		OR ( @last_nsf_date != @today ))
		BEGIN
			UPDATE	#aractter_work
			SET		date_last_nsf = @today,
					amt_last_nsf = @t_amt_applied,
					last_nsf_doc = @t_dcn,
					last_trx_time = ( last_trx_time / 1000 ) * 1000 + @short_time
			WHERE	territory_code = @t_ter_code
		END
		ELSE
		BEGIN
			UPDATE	#aractter_work
			SET		amt_last_nsf = amt_last_nsf + @t_amt_applied
			WHERE	territory_code = @t_ter_code
		END

		IF ( @t_trx_time != (	SELECT	last_trx_time
								FROM	#arsumter_work
								WHERE	territory_code = @t_ter_code 
	 							 AND	date_thru = @t_period_end ))
		BEGIN
			UPDATE	#arsumter_work
			SET		num_nsf	= ISNULL(num_nsf, 0) + 1,
					amt_nsf	= ISNULL(amt_nsf, 0) + @t_amt_applied,
					last_trx_time = @t_trx_time
			WHERE	territory_code = @t_ter_code
			 AND	date_thru = @t_period_end
		END
		ELSE
		BEGIN
			UPDATE	#arsumter_work
			SET		amt_nsf	= ISNULL(amt_nsf, 0.0) + @t_amt_applied
			WHERE	territory_code = @t_ter_code
		 	 AND	date_thru = @t_period_end
		END
	END	

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARPYNSFActivity_SP] TO [public]
GO
