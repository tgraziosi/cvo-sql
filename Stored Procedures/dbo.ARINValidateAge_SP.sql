SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINValidateAge_SP]	@error_level	smallint,
					@trx_type	smallint,
					@debug_level	smallint = 0
AS

DECLARE	
	@result	smallint


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinva.sp" + ", line " + STR( 51, 5 ) + " -- ENTRY: "

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20068 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinva.sp" + ", line " + STR( 58, 5 ) + " -- MSG: " + "Validate that the amt due for all aging components in the aging table are positive"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20068,
			"",
			"",
			0,
			amt_due,
			4,
			trx_ctrl_num,
			0,
			"",
			0
		FROM 	#arvalage
	 	WHERE 	((amt_due) < (0.0) - 0.0000001)
		AND	#arvalage.trx_type != 2021 
	END
	

	
	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20069 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinva.sp" + ", line " + STR( 88, 5 ) + " -- MSG: " + "Validate that the amt due in the aging table equals the net amt for document"
		
		CREATE TABLE #tmp
		(	
			trx_ctrl_num	varchar( 16 ),
			trx_type	smallint,
			sum_amt_due	float
		)
		
		INSERT #tmp
		SELECT trx_ctrl_num, trx_type, sum(amt_due) 
		FROM	#arvalage 
		GROUP BY #arvalage.trx_ctrl_num, #arvalage.trx_type

		
		INSERT	#ewerror
		SELECT 2000,
		 	20069,
			"",
			"",
			0,
			a.amt_due,
			4,
			a.trx_ctrl_num,
			0,
			"",
			0
		FROM 	#arvalchg a, #tmp b
	 	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = b.trx_type
		AND	(ABS((a.amt_net)-(b.sum_amt_due)) > 0.0000001)
		
		DROP TABLE #tmp
	END


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinva.sp" + ", line " + STR( 127, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateAge_SP] TO [public]
GO
