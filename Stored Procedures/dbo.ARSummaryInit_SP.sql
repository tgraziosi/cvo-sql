SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 








































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARSummaryInit_SP]	@batch_ctrl_num		varchar( 16 ),
								@is_cus_code 		varchar( 8 ),	
								@is_prc_code 		varchar( 8 ),	
								@is_shp_code 		varchar( 8 ),
								@is_slp_code 		varchar( 8 ),	
								@is_ter_code 		varchar( 8 ),	
								@is_date_applied 	int,
								@debug_level		smallint = 0,
								@perf_level			smallint = 0
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	
		@cus_flag		smallint,	
		@prc_flag 		smallint,	
		@shp_flag 		smallint,
		@slp_flag 		smallint,	
		@ter_flag 		smallint,	
		@mast_flag 		smallint,
		@date_from 		int,		
		@date_thru 		int,
		@err_mess 		char(80),	
		@err_mess_date 	char(12)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsi.sp", 88, "Entering ARSummaryInit_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 91, 5 ) + " -- ENTRY: "

	
	SELECT	@cus_flag = arsumcus_flag, 
			@prc_flag = arsumprc_flag, 
			@shp_flag = arsumshp_flag, 
			@slp_flag = arsumslp_flag, 
			@ter_flag = arsumter_flag
	FROM	arco
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 104, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	SELECT	@mast_flag = NULL

	SELECT	@mast_flag = ship_to_history
	FROM	arcust
	WHERE	customer_code = @is_cus_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @mast_flag = NULL )
		SELECT	@mast_flag = 0

	
	SELECT	@date_thru = period_end_date,
			@date_from = period_start_date
	FROM 	glprd
	WHERE	period_end_date >= @is_date_applied
	 AND	period_start_date <= @is_date_applied
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 137, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	
	IF (( @cus_flag = 1 ) AND ( @is_cus_code != NULL ) AND ( @is_cus_code != SPACE(10))
	AND NOT EXISTS( SELECT date_thru FROM #arsumcus_work
		WHERE customer_code = @is_cus_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
	BEGIN
		INSERT	#arsumcus_work
		(
			customer_code,	
			date_from,	
			date_thru
		)
		VALUES	
		(
			@is_cus_code,	
			@date_from,	
			@date_thru
		)
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 163, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END 

	
	IF (( @prc_flag = 1 ) AND ( @is_prc_code != NULL ) AND ( @is_prc_code != SPACE(10))
	AND NOT EXISTS( SELECT date_thru FROM #arsumprc_work
			WHERE price_code = @is_prc_code
			 AND @is_date_applied BETWEEN date_from AND date_thru ) )
	BEGIN
		INSERT	#arsumprc_work
		(
			price_code,	
			date_from,	
			date_thru
		)
		VALUES	
		(
			@is_prc_code,	
			@date_from,	
			@date_thru
		)
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 190, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END 

	
	IF (( @shp_flag = 1 ) AND ( @is_shp_code != NULL ) 
	AND ( @is_shp_code != SPACE(10)) AND ( @mast_flag = 1 ) 
	AND ( @is_cus_code != NULL ) AND ( @is_cus_code != SPACE(10) )
	AND NOT EXISTS( SELECT	date_thru FROM #arsumshp_work
		WHERE	customer_code = @is_cus_code
		 AND	ship_to_code = @is_shp_code
		 AND	@is_date_applied BETWEEN date_from AND date_thru ) )
	BEGIN
		INSERT #arsumshp_work
		(
			ship_to_code,
			customer_code,	
			date_from,	
			date_thru
		)
		VALUES	
		(
			@is_shp_code,
			@is_cus_code,	
			@date_from,	
			@date_thru
		)
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 222, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END 

	
	IF (( @slp_flag = 1 ) AND ( @is_slp_code != NULL ) 
	AND ( @is_slp_code != SPACE(10))
	AND NOT EXISTS( SELECT date_thru FROM #arsumslp_work
		WHERE salesperson_code = @is_slp_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
	BEGIN
		INSERT #arsumslp_work
		(
			salesperson_code, 
			date_from,	
			date_thru
		)
		VALUES	
		(	
			@is_slp_code,	
			@date_from,	
			@date_thru
		)
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 250, 5 ) + " -- EXIT: "
			RETURN 34563

		END 
	END
	
	IF (( @ter_flag = 1 ) AND ( @is_ter_code != NULL ) 
	AND ( @is_ter_code != SPACE(10))
	AND NOT EXISTS( SELECT date_thru FROM #arsumter_work
			WHERE territory_code = @is_ter_code
		 	AND @is_date_applied BETWEEN date_from AND date_thru ) )
	BEGIN
		INSERT	#arsumter_work
		(
			territory_code, 
			date_from,	
			date_thru
		)
		VALUES	
		(
			@is_ter_code,	
			@date_from,	
			@date_thru
		)
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 278, 5 ) + " -- EXIT: "
			RETURN 34563
		END 
	END
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arsi.sp" + ", line " + STR( 282, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arsi.sp", 283, "Entering ARSummaryInit_SP", @PERF_time_last OUTPUT
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARSummaryInit_SP] TO [public]
GO
