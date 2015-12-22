SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCRResetFlags_SP] 	@batch_ctrl_num	varchar(16),
					@process_ctrl_num 	varchar(16),
					@batch_proc_flag    	smallint,
					@process_user_id	smallint,
                                	@debug_level        	smallint = 0,
					@perf_level		smallint = 0    
    					 

AS

DECLARE
    	@result             	int,
	@tran_started		smallint

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "
	   




	
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


 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 69, 5 ) + " -- MSG: " + "Charge Credit Cards for Cash receipts with CC Paymenth method "
	
	EXEC @result = archargecca_sp

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
		


		DECLARE @provider int
		SELECT @provider = configuration_int_value FROM icv_config WHERE configuration_item_name = 'Processor Interface'
		
		IF @provider = 2
			UPDATE #arinppyt_work
				SET prompt4_inp = new_prompt4_inp
			FROM #arinppyt_work a 
				INNER JOIN  #arccatransactions b
			         	ON a.trx_ctrl_num = b.trx_ctrl_num
					AND a.trx_type = b.trx_type
				WHERE  b.charged = 0 AND a.hold_flag =0

		ELSE IF EXISTS (SELECT 1 FROM arco WHERE authorize_onsave <>1) 
			UPDATE #arinppyt_work
				SET prompt4_inp = new_prompt4_inp
			FROM #arinppyt_work a 
				INNER JOIN  #arccatransactions b
			         	ON a.trx_ctrl_num = b.trx_ctrl_num
					AND a.trx_type = b.trx_type
				WHERE  b.charged = 0 AND a.hold_flag =0
		IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		
		DROP TABLE #arccatransactions
		IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 136, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		 
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 140, 5 ) + " -- EXIT: "
	    	RETURN 0
	END

	
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
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 158, 5 ) + " -- EXIT: "
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
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 183, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	IF( @batch_proc_flag = 1 )
	BEGIN
		



		UPDATE	#arinppyt_work 
		SET	hold_flag = 1,
			db_action = db_action | 1
		FROM	#arinppyt_work a, #ewerror b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2111
		


		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 205, 5 ) + " -- EXIT: "
			RETURN 34563
		END

		


		UPDATE	#arinppyt_work 
		SET	posted_flag = 0,
			   
			db_action = db_action | 1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 218, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		


		UPDATE	#artrx_work
		SET	posted_flag = 1,
			process_group_num = trx_ctrl_num,
			db_action = db_action | 1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 231, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		





		IF( @@trancount = 0 )
		BEGIN
			BEGIN TRAN
			SELECT	@tran_started = 1
		END

		

					
		IF EXISTS(SELECT 1 FROM #ewerror )  
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							5
		ELSE
			EXEC @result = batupdst_sp	@batch_ctrl_num,
							0
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 258, 5 ) + " -- EXIT: "
			RETURN 34563
		END

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
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 273, 5 ) + " -- EXIT: "
			RETURN @result
		END
		
		IF( @tran_started = 1 )
		BEGIN
			COMMIT TRAN
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 282, 5 ) + " -- EXIT: "
				RETURN 34563
			END
		END

		




		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 292, 5 ) + " -- EXIT: "
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
		AND	a.trx_type = 2111
		AND	err_code != 34554
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 319, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrrf.cpp" + ", line " + STR( 324, 5 ) + " -- EXIT: "
	
	



	RETURN 34570
END
GO
GRANT EXECUTE ON  [dbo].[ARCRResetFlags_SP] TO [public]
GO
