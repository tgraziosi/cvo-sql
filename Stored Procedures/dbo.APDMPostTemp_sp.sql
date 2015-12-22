SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APDMPostTemp_sp]
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


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpt.cpp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "

SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num


EXEC @result = APDMUpdateExtendedAmounts_sp  @debug_level

IF (@result != 0)
	        RETURN @result


EXEC @result = APDMProcessGLEntries_sp  @process_group_num,
										@date_applied,
										@batch_ctrl_num,
										@user_id,
										@journal_ctrl_num OUTPUT,
										@debug_level

IF (@result != 0)
	        RETURN @result



EXEC @result = APDMProcessPayments_sp   @process_group_num,
										@user_id,
				   						@debug_level
IF (@result != 0)
        		RETURN @result


IF EXISTS(SELECT 1 FROM #apdmchg_work
			WHERE ((amt_restock) > (0.0) + 0.0000001))
BEGIN

	EXEC @result = APDMProcessVouchers_sp   @debug_level
	IF (@result != 0)
        		RETURN @result
END


EXEC @result = APDMInsertPostedRecords_sp 	@journal_ctrl_num,
											@date_applied,
											@debug_level
IF (@result != 0)
	        RETURN @result



EXEC @result = APDMVendorActSum_sp	@debug_level

IF @result != 0
	    RETURN @result


EXEC @result = APDMDeleteInputTables_sp	@debug_level

IF @result != 0
	    RETURN @result


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmpt.cpp" + ", line " + STR( 138, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMPostTemp_sp] TO [public]
GO
