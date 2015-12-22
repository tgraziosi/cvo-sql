SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[APVOUpdateTables_sp]
									@batch_ctrl_num		varchar(16),
									@debug_level		smallint = 0

AS

DECLARE
	@process_group_num 	varchar(16),
	@sys_date           int,
	@period_end         int,
	@errbuf             varchar(100),
	@client_id 			varchar(20),
	@user_id			int,  
	@batch_type			smallint,
    @result 			int,
	@next_period        int,
	@home_cur_code varchar(8),
	@oper_cur_code varchar(8),
	@date_applied       int


BEGIN

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvout.cpp" + ", line " + STR( 109, 5 ) + " -- ENTRY: "

	SELECT  @user_id = NULL,
			@client_id = "APPOSTING"

    EXEC @result = batinfo_sp  	@batch_ctrl_num,
							  	@process_group_num 	OUTPUT,
								@user_id		OUTPUT,
								@sys_date		OUTPUT,
								@period_end		OUTPUT,
								@batch_type		OUTPUT
	IF( @result != 0 )
		RETURN -1








CREATE TABLE #rates (from_currency varchar(8),
			   to_currency varchar(8),
			   rate_type varchar(8),
			   date_applied int,
			   rate float)

IF @@error <> 0
		   RETURN -1


--IF EXISTS (SELECT 1 FROM apinpchg
--		   WHERE batch_code = @batch_ctrl_num
--		   AND accrual_flag = 1)

IF EXISTS (SELECT 1 FROM apinpchg_all (nolock)
		   WHERE batch_code = @batch_ctrl_num
		   AND accrual_flag = 1)


BEGIN		   	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvout.cpp" + ", line " + STR( 151, 5 ) + " -- MSG: " + "lookup accrual voucher rates"



SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num


SELECT @next_period = 0

SELECT  @next_period = MIN( period_start_date )
FROM    glprd (nolock)
WHERE   period_start_date > @date_applied


SELECT @home_cur_code = home_currency,
	   @oper_cur_code = oper_currency
	   FROM glco

		



		INSERT #rates  (from_currency,
						to_currency,
						rate_type,
						date_applied,
						rate)
		SELECT DISTINCT nat_cur_code,
						@home_cur_code,
						rate_type_home,
						@next_period,
						0.0
		FROM apinpchg_all (nolock)
	    WHERE batch_code = @batch_ctrl_num
		AND accrual_flag = 1
		
		UNION ALL
		





		SELECT DISTINCT nat_cur_code,
						@oper_cur_code,
						rate_type_oper,
						@next_period,
						0.0
		FROM apinpchg_all (nolock)
	    WHERE batch_code = @batch_ctrl_num
		AND accrual_flag = 1
						
		EXEC CVO_Control..mcrates_sp

END
	



	BEGIN TRAN final_state

	




	EXEC @result = APVOUpdatePersistant_sp	@batch_ctrl_num,
											@process_group_num,
											@client_id,
											@user_id,
											@debug_level


	IF( @result	!= 0 )
	BEGIN
		ROLLBACK TRAN final_state
		RETURN @result
	END







	EXEC	@result = batupdst_sp	@batch_ctrl_num, 1
	IF(@result != 0)
			RETURN -1


	DECLARE @count INTEGER
	DECLARE @amt_net FLOAT

	SET @count = (SELECT COUNT(1) FROM #apvochg_work)
	SET @amt_net = (SELECT ISNULL(SUM(amt_net),0.0) FROM #apvochg_work)

	UPDATE pbatch
	SET end_number = @count,
		end_total = @amt_net,
		end_time = getdate(),
		flag = 2
	WHERE batch_ctrl_num = @batch_ctrl_num
	AND process_ctrl_num = @process_group_num

	COMMIT TRAN final_state

	







	EXEC ap_vouch_sp @batch_ctrl_num

	
	







	DROP TABLE #rates


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvout.cpp" + ", line " + STR( 281, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APVOUpdateTables_sp] TO [public]
GO
