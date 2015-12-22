SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCAResetFlags_SP] 	@batch_ctrl_num	varchar(16),
					@process_ctrl_num 	varchar(16),
					@batch_proc_flag    	smallint,
					@process_user_id	smallint,
                                	@debug_level        	smallint = 0,
					@perf_level		smallint = 0    
    					 

AS

DECLARE
	@company_code		varchar(8),
    	@result             	int,
	@tran_started		smallint

BEGIN



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "
        


	
CREATE TABLE #arccatransactions
	(
	 trx_ctrl_num 	varchar(16), 
	 trx_type	smallint,
	 prompt1_inp	varchar(30), 
	 prompt2_inp	varchar(30), 
   	 prompt3_inp	varchar(30),
	 prompt4_inp	varchar(30),
	amt_payment	float, 
	trx_code		varchar(3),
	 new_prompt4_inp varchar(30),
	nat_cur_code	varchar(8),
	 charged	smallint
	)


	 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 67, 5 ) + " -- MSG: " + "Refund Credit Cards for Cash receipts with CC Paymenth method "

	EXEC @result = arrefundcca_sp

	 IF ( SELECT e_level FROM aredterr WHERE e_code = 20922 ) >= 3
		BEGIN
			INSERT  #ewerror
			SELECT 2000,
			      20922,
			      a.prompt2_inp,
			      a.prompt4_inp,
			      0,
			      0.0,
			      0,
			      a.trx_ctrl_num,
			      0,
			      ISNULL(source_trx_ctrl_num, ""),
			      0
			    FROM  #arinppyt_work a
				INNER JOIN  #arccatransactions b
			         	ON a.trx_ctrl_num = b.trx_ctrl_num
					AND a.trx_type = b.trx_type
			WHERE  b.charged <> 0
		END
	 


	



	IF (( SELECT COUNT(*) FROM #ewerror ) = 0)
	BEGIN
		


		UPDATE #arinppyt_work
			SET prompt4_inp = new_prompt4_inp
		FROM #arinppyt_work a 
			INNER JOIN  #arccatransactions b
		         	ON a.trx_ctrl_num = b.trx_ctrl_num
				AND a.trx_type = b.trx_type
			WHERE  b.charged = 0 AND a.hold_flag =0
		
		DROP TABLE #arccatransactions
		IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 114, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		 
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 118, 5 ) + " -- EXIT: "
	    	RETURN 0
	END
	
	
	DROP TABLE #arccatransactions
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 126, 5 ) + " -- EXIT: "
			RETURN 34563
		END
        
	


	INSERT perror
	(	process_ctrl_num,	batch_code,	module_id,
		err_code,		info1,		info2,
		infoint,    		infofloat, 	flag1,
		trx_ctrl_num,	    	sequence_id,	source_ctrl_num,
		extra
	)
	SELECT	@process_ctrl_num,	@batch_ctrl_num,	module_id,
		err_code,		info1,	     		info2,
		infoint,   		infofloat,  		flag1,
		trx_ctrl_num,		sequence_id,		source_ctrl_num,
		extra 
	FROM 	#ewerror

	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 149, 5 ) + " -- EXIT: "
			RETURN 34563
		END

	IF( @batch_proc_flag = 1 )
	BEGIN
		




		


		UPDATE	#arinppyt_work 
		SET	hold_flag = 1,
			db_action = db_action | 1
		FROM	#arinppyt_work a, #ewerror b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	b.err_code != 20900

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 172, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		


		UPDATE	#arinppyt_work 
		SET	posted_flag = 0,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 186, 5 ) + " -- EXIT: "
			RETURN 34563
		END
			
		

		UPDATE	#arnonardet_work 
		SET	#arnonardet_work.db_action = 1
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arnonardet_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	hold_flag = 0

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		UPDATE	#arinptax_work 
		SET	#arinptax_work.db_action = 1
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arinptax_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	hold_flag = 0		

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 214, 5 ) + " -- EXIT: "
			RETURN 34563
		END



		UPDATE	#arnonardet_work 
		SET	#arnonardet_work.db_action = 0
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arnonardet_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	hold_flag = 1

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 229, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE	#arinptax_work 
		SET	#arinptax_work.db_action = 0
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arinptax_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	hold_flag = 1		

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 242, 5 ) + " -- EXIT: "
			RETURN 34563
		END

				

		


		UPDATE	#artrx_work
		SET	posted_flag = 1,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1
		WHERE	posted_flag = -1

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 259, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		


		SELECT	@company_code = company_code
		FROM	glco

		





		IF( @@trancount = 0 )
		BEGIN
			BEGIN TRAN
			SELECT	@tran_started = 1
		END

		

					
		IF EXISTS(SELECT 1 FROM #ewerror WHERE err_code != 20900 )
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							5
		ELSE
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							0
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 292, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		





		UPDATE	#arinppyt_work
		SET	trx_type = 2121
		WHERE	batch_code = @batch_ctrl_num


		UPDATE	#arnonardet_work
		SET	trx_type = 2121
		FROM	#arinppyt_work pyt , #arnonardet_work det
		WHERE	pyt.trx_ctrl_num 	= det.trx_ctrl_num
		AND	pyt.batch_code 		= @batch_ctrl_num	
	

		UPDATE 	#arinptax_work
		SET	trx_type = 2121
		FROM	#arinppyt_work pyt
		WHERE	#arinptax_work.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pyt.batch_code = @batch_ctrl_num

			
		UPDATE #arinppdt_work
		SET	trx_type = 2121
		FROM	#arinppyt_work pyt
		WHERE	#arinppdt_work.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pyt.batch_code = @batch_ctrl_num

		EXEC @result = ARModifyPersistant_SP	@batch_ctrl_num,
								@debug_level,
 								@perf_level
		IF( @result != 0 )
		BEGIN
			IF( @tran_started = 1 )
			BEGIN
				ROLLBACK TRAN
				SELECT	@tran_started = 0
			END
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 337, 5 ) + " -- EXIT: "
			RETURN @result
		END
		
		IF( @tran_started = 1 )
		BEGIN
			COMMIT TRAN
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 346, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END

		




		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 356, 5 ) + " -- EXIT: "
		RETURN 34562
	END
	ELSE       
	BEGIN
		IF( @debug_level >= 2 )
		BEGIN
			SELECT	"Transaction to be put on hold"
			SELECT	"trx_ctrl_num = " + trx_ctrl_num  
			FROM	#ewerror
		END

		


		UPDATE	#arinppyt_work 
		SET	batch_code = ' ',
			posted_flag = 0,
			process_group_num = a.trx_ctrl_num,
			hold_flag = 1,
			db_action = db_action | 1
		FROM	#arinppyt_work a, #ewerror b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	err_code != 34554

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 383, 5 ) + " -- EXIT: "
			RETURN @result
		END

		

		UPDATE	#arnonardet_work 
		SET	#arnonardet_work.db_action = 1
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arnonardet_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	pyt.hold_flag	= 0

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 398, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		UPDATE	#arinptax_work 
		SET	#arinptax_work.db_action = 1
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arinptax_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	pyt.hold_flag	= 0

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 411, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE	#arnonardet_work 
		SET	#arnonardet_work.db_action = 0
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arnonardet_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	hold_flag = 1

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 424, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		UPDATE	#arinptax_work 
		SET	#arinptax_work.db_action = 0
		FROM	#arinppyt_work pyt
		WHERE	pyt.trx_ctrl_num = #arinptax_work.trx_ctrl_num
		AND	pyt.db_action	 = 1
		AND	hold_flag = 1		

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 437, 5 ) + " -- EXIT: "
			RETURN 34563
		END


				


	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcarf.cpp" + ", line " + STR( 447, 5 ) + " -- EXIT: "
	
	



	RETURN 34570
END
GO
GRANT EXECUTE ON  [dbo].[ARCAResetFlags_SP] TO [public]
GO
