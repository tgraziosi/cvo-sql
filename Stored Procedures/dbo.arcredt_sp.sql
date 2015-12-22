SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[arcredt_sp]	@only_error		smallint,
				@called_from		smallint,
				@debug_level		smallint = 0
AS

DECLARE	
	@result	smallint,
	@error_level	smallint
	

IF OBJECT_ID('#artrx_work') IS NOT NULL
   BEGIN
	select t.trx_ctrl_num as Ptrx_ctrl_num, c.trx_ctrl_num as Ctrx_ctrl_num, c.doc_ctrl_num, c.date_due
 	  into #t
	  from #artrx_work t (nolock)
	   join #artrxage_work  a (nolock) on t.trx_ctrl_num = a.trx_ctrl_num
	   join #artrx_work c (nolock) on t.doc_ctrl_num = c.doc_ctrl_num and c.trx_type = 2032 
	 where a.trx_type = 2161 
		AND 	t.trx_type in (2111,2161)	
 		AND 	(amount > 0.000001 or amount < -0.000001 )
		AND 	a.apply_to_num = a.doc_ctrl_num
		AND 	t.paid_flag = 0
		AND 	ref_id = 0
		AND		c.date_due <> t.date_due
		
	-- update age	
	update 	#artrxage_work set #artrxage_work.date_due = #t.date_due
	  from #t
	 where #artrxage_work.trx_ctrl_num = #t.Ptrx_ctrl_num

	-- update trx
	update 	#artrx_work set #artrx_work.date_due = #t.date_due
	  from #t
	 where #artrx_work.trx_ctrl_num = #t.Ptrx_ctrl_num

	drop table  #t
   END


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcredt.sp" + ", line " + STR( 31, 5 ) + " -- ENTRY: "

	
	IF ((	SELECT COUNT(*) 
		FROM #arvalpyt) < 1) 
		RETURN 0
		
	
	IF @only_error = 1
		SELECT @error_level = 3
	ELSE
		SELECT @error_level = 2

	
	EXEC @result = ARCRValidateHeader1_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcredt.sp" + ", line " + STR( 55, 5 ) + " -- EXIT: "
		RETURN @result
	END

	
	EXEC @result = ARCRValidateHeader2_SP	@error_level,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcredt.sp" + ", line " + STR( 67, 5 ) + " -- EXIT: "
		RETURN @result
	END


	
	EXEC @result = ARCRValidateDetail1_SP	@error_level,
							@called_from,
							@debug_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcredt.sp" + ", line " + STR( 80, 5 ) + " -- EXIT: "
		RETURN @result
	END

	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[arcredt_sp] TO [public]
GO
