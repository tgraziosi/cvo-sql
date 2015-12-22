SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcapt.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                












 



					 










































 






















































































































































































































































































































































































































































































































 
















































































CREATE PROC [dbo].[ARCAPostTemp_SP]	@batch_ctrl_num	varchar(16),
				@process_ctrl_num	varchar(16),
				@debug_level		smallint,
				@perf_level		smallint

AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
	@result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcapt.sp", 58, "Entering ARCAPostTemp_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapt.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "

	
	
CREATE TABLE #arcatemp
(
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	journal_ctrl_num	varchar(16),
)


	
	
CREATE TABLE #arsumshp_pre
(
	customer_code		varchar(8),
	ship_to_code		varchar(8),
	num_inv_paid		int
)

CREATE INDEX #arsumshp_pre_ind_0
	ON #arsumshp_pre ( customer_code, ship_to_code )

	
CREATE TABLE #arsumter_pre
(
	territory_code	varchar(8),
	num_inv_paid		int
)

CREATE INDEX #arsumter_pre_ind_0
	ON #arsumter_pre ( territory_code )

	
CREATE TABLE #arsumslp_pre
(
	salesperson_code	varchar(8),
	num_inv_paid		int
)

CREATE INDEX #arsumslp_pre_ind_0
	ON #arsumslp_pre ( salesperson_code )

	
CREATE TABLE #arsumprc_pre
(
	price_code		varchar(8),
	num_inv_paid		int
)

CREATE INDEX #arsumprc_pre_ind_0
	ON #arsumprc_pre ( price_code )

	
CREATE TABLE #arsumcus_pre
(
	customer_code		varchar(8),
	num_inv_paid		int
)

CREATE INDEX #arsumcus_pre_ind_0
	ON #arsumcus_pre ( customer_code )

	
CREATE TABLE #aractcus_pre
(
	customer_code		varchar(8),
	amt_on_acct_home	float NULL,
	amt_on_acct_oper	float NULL
)
	

CREATE INDEX #aractcus_pre_ind_0
	ON #aractcus_pre ( customer_code )



	EXEC @result = ARCACreateDependantTrans_SP 	@batch_ctrl_num,
								@debug_level,
								@perf_level


	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapt.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
		RETURN @result
	END

	EXEC @result = ARCAUpdateDependTrans_SP 	@batch_ctrl_num,
							@process_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapt.sp" + ", line " + STR( 99, 5 ) + " -- EXIT: "
		RETURN @result
	END

	EXEC @result = ARCACreateAgingRecs_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapt.sp" + ", line " + STR( 109, 5 ) + " -- EXIT: "
		RETURN @result
	END


	EXEC @result = ARCAUpdateActivitySummary_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapt.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN @result
	END
	
	
	DROP TABLE #aractcus_pre
	DROP TABLE #arsumcus_pre
	DROP TABLE #arsumslp_pre
	DROP TABLE #arsumprc_pre
	DROP TABLE #arsumter_pre
	DROP TABLE #arsumshp_pre

	EXEC @result = ARCAMoveUnpostedRecords_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcapt.sp" + ", line " + STR( 141, 5 ) + " -- EXIT: "
		RETURN @result
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcapt.sp", 145, "Returning from ARCAPostTemp_SP", @PERF_time_last OUTPUT
	RETURN 0

	DROP TABLE #arcatemp


END

GO
GRANT EXECUTE ON  [dbo].[ARCAPostTemp_SP] TO [public]
GO
