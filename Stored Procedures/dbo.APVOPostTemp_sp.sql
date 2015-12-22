SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVOPostTemp_sp] 
								@batch_ctrl_num varchar(16),
								@process_group_num 	varchar(16),
								@user_id				int,  
								@cm_exist 				smallint,
			 					@period_end 			int,
								@debug_level 			smallint = 0

AS





DECLARE	@date_applied int,
		@result  int,
		@journal_ctrl_num varchar(16)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvopt.cpp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "

SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num


EXEC @result = APVOUpdateExtendedAmounts_sp  @debug_level

IF (@result != 0)
	        RETURN @result


EXEC @result = APVOProcessGLEntries_sp  @process_group_num,
										@date_applied,
										@batch_ctrl_num,
										@user_id,
										@journal_ctrl_num OUTPUT,
										@debug_level

IF (@result != 0)
	        RETURN @result





IF EXISTS (SELECT 1 FROM #apvochg_work
           WHERE accrual_flag = 1)
BEGIN
	 DELETE #apvotmp_work
	 FROM #apvotmp_work a, #apvochg_work b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.accrual_flag = 1

	 IF @@error != 0
	    RETURN -1

	 DELETE #apvotax_work
	 FROM #apvotax_work a, #apvochg_work b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.accrual_flag = 1

	 IF @@error != 0
	    RETURN -1

	 DELETE #apvotaxdtl_work
	 FROM #apvotaxdtl_work a, #apvochg_work b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.accrual_flag = 1

	 IF @@error != 0
	    RETURN -1

	 DELETE #apvoage_work
	 FROM #apvoage_work a, #apvochg_work b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.accrual_flag = 1

	 IF @@error != 0
	    RETURN -1

	 DELETE #apvocdt_work
	 FROM #apvocdt_work a, #apvochg_work b
	 WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 AND b.accrual_flag = 1
	 
	 IF @@error != 0
	    RETURN -1

	 DELETE #apvochg_work
	 WHERE accrual_flag = 1

	 IF @@error != 0
	    RETURN -1

END


IF EXISTS (SELECT 1 FROM #apvochg_work
           WHERE one_time_vend_flag = 1)
BEGIN

	EXEC @result = APVOProcessOneTimeVendors_sp   @debug_level
	IF (@result != 0)
        		RETURN @result
END


EXEC @result = APVOProcessPayments_sp   @process_group_num,
				   						@debug_level
IF (@result != 0)
        		RETURN @result


IF EXISTS(SELECT 1 FROM #apvochg_work
			WHERE recurring_flag = 1)
BEGIN

	EXEC @result = APVOProcessVouchers_sp   @debug_level
	IF (@result != 0)
        		RETURN @result
END	
				

EXEC @result = APVOInsertPostedRecords_sp 	@journal_ctrl_num,
											@date_applied,
											@debug_level
IF (@result != 0)
	        RETURN @result



EXEC @result = APVOVendorActSum_sp	@debug_level

IF @result != 0
	    RETURN @result



EXEC @result = APVODeleteInputTables_sp	@debug_level

IF @result != 0
	    RETURN @result


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvopt.cpp" + ", line " + STR( 198, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOPostTemp_sp] TO [public]
GO
