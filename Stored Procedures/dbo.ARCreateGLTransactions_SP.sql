SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCreateGLTransactions_SP]	@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result             		int,
	@journal_type			varchar(8),
	@process_ctrl_num		varchar(16),
	@journal_ctrl_num		varchar(16),
	@journal_description		varchar(40),
	@user_id			smallint,
	@date_entered			int,
	@period_end			int,
	@batch_type			smallint,
	@company_code			varchar(8),
	@trx_type			smallint,
	@date_applied			int,
	@last_journal_type		varchar(8),
	@home_cur_code		varchar(8),
	@oper_cur_code		varchar(8),
	@org_id			varchar(30),
	@interbranch_flag		int,
	@count_org_id			int,
	@where			varchar(20),
	@last_org_id	varchar(30)


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcglt.cpp', 145, 'Entering ARCreateGLTransactions_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 148, 5 ) + ' -- ENTRY: '

	






















	



	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@user_id OUTPUT,
					@date_entered OUTPUT,
					@period_end OUTPUT,
					@batch_type OUTPUT

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 186, 5 ) + ' -- EXIT: '
		RETURN 35011
	END

	



	SET rowcount 1

	SELECT	DISTINCT @journal_description = journal_description
	FROM	#argldist

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 201, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	





	SELECT	DISTINCT @trx_type = trx_type
	FROM	#argldist

	IF( @@error != 0 ) 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 216, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	





	SELECT DISTINCT @date_applied = date_applied
	FROM	#argldist

	IF( @@error != 0 ) 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 231, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	SET rowcount 0

	







	SELECT	@company_code 		= company_code,
		@home_cur_code 		= home_currency,
		@oper_cur_code 		= oper_currency,
		@interbranch_flag 	= ib_flag 
	FROM	glco

	




	SELECT @count_org_id = 0

        IF (@trx_type in (2021,2031,2032,2051,2161))
        BEGIN
        	SELECT 	@org_id	= org_id	
        	FROM	#arinpchg_work
        	WHERE	batch_code = @batch_ctrl_num
	
		


		IF @interbranch_flag = 1
		BEGIN
			SELECT 	@count_org_id = COUNT(d.org_id)
			FROM	#arinpchg_work h,  #arinpcdt_work d
			WHERE	h.trx_ctrl_num 	= d.trx_ctrl_num
			AND	h.org_id 	!= d.org_id 

			



			IF (@trx_type = 2051)
			BEGIN
				SELECT 	@count_org_id = COUNT(d.org_id)
				FROM	#arinpchg_work h,  #arinpcdt_work d
				WHERE	h.trx_ctrl_num 	= d.trx_ctrl_num
				AND	h.org_id 	!= d.org_id 
				AND 	d.gl_rev_acct 	!= d.new_gl_rev_acct
			END

			


			IF (@trx_type = 2021)
			BEGIN
				SELECT 	@count_org_id = COUNT(rev.org_id)
				FROM	#arinpchg_work chg, #arinprev_work rev
				WHERE	chg.batch_code	= @batch_ctrl_num
				AND	chg.trx_ctrl_num = rev.trx_ctrl_num
				AND	chg.trx_type	= rev.trx_type
				AND	chg.org_id	!= rev.org_id 
			END

			IF @count_org_id = 0
				SELECT 	@interbranch_flag = 0

		END

        END
        ELSE IF (@trx_type in (2112,2113,2151))
        BEGIN
        	SELECT 	@org_id	= org_id	
        	FROM	#arinppyt_work
        	WHERE	batch_code = @batch_ctrl_num
		
		


		IF @interbranch_flag = 1
		BEGIN
		
			SELECT 	@count_org_id = COUNT(d.org_id)
			FROM	#arinppyt_work h,  #arinppdt_work d
			WHERE	h.trx_ctrl_num 	= d.trx_ctrl_num
			AND	h.org_id 	!= d.org_id 
						
			IF @count_org_id = 0
				SELECT 	@interbranch_flag = 0
		
		END
        END
 	ELSE IF (@trx_type IN (2111,2121))  
        BEGIN
        	SELECT 	@org_id	= org_id	
        	FROM	#arinppyt_work
        	WHERE	batch_code = @batch_ctrl_num
		
		


		IF @interbranch_flag = 1
		BEGIN
		
			SELECT 	@count_org_id = COUNT(d.org_id)
			FROM	#arinppyt_work h,  #arinppdt_work d
			WHERE	h.trx_ctrl_num 	= d.trx_ctrl_num
			AND	h.org_id 	!= d.org_id 
		
			
			


			IF  (SELECT COUNT(trx_ctrl_num) FROM #arnonardet_work) > 0
			BEGIN
				SELECT 	@count_org_id 	= COUNT(p.org_id)
				FROM	#arinppyt_work p, #arnonardet_work d
				WHERE	p.trx_ctrl_num 	= d.trx_ctrl_num
				AND	p.trx_type 	= d.trx_type
				AND	p.org_id	!= d.org_id

			END
	
			IF @count_org_id = 0
				SELECT 	@interbranch_flag = 0
		
		END
        END




	IF( @@error != 0 ) 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 370, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	


	
CREATE TABLE #gldist
(
    journal_ctrl_num	varchar(16),
	rec_company_code	varchar(8),	
    account_code		varchar(32),	
	description		varchar(40),
    document_1		varchar(16), 	
    document_2		varchar(16), 	
	reference_code		varchar(32),	
    balance			float,		
	nat_balance		float,		
	nat_cur_code		varchar(8),	
	rate			float,		
	trx_type		smallint,
	seq_ref_id		int,		
    balance_oper            float NULL,
    rate_oper               float NULL,
    rate_type_home          varchar(8) NULL,
    rate_type_oper          varchar(8) NULL,
 org_id		varchar(30) NULL
)



	IF NOT EXISTS(SELECT 1 FROM #argldist WHERE trx_type in (2061, 2071))
	BEGIN
		

		


		SELECT	@last_journal_type = '',
			@journal_type = NULL

		




		WHILE(1 = 1)		
		BEGIN
			

  
			SELECT	@journal_type = MIN(journal_type)
			FROM	#argldist
			WHERE	journal_type > @last_journal_type
	
			IF( @@error != 0 ) 
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 406, 5 ) + ' -- EXIT: '
				RETURN 34563
			END

			


	
			IF( @journal_type IS NULL )
				BREAK

			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 417, 5 ) + ' -- MSG: ' + 'Processing journal_type ' + @journal_type

			


			EXEC @result = gltrxcrh_sp	@process_ctrl_num,		
							-1,		
							2000,	
							2,			
							@journal_type,		
							@journal_ctrl_num OUTPUT,	
							@journal_description,	
							@date_entered,		
							@date_applied,		
							0,				
							0,				
							0,				
							@batch_ctrl_num,		
							0,			
							@company_code,		
							@company_code,		
							@home_cur_code,		
							' ',				
							@trx_type,			
							@user_id,			
							0,				
							@oper_cur_code,		
							@debug_level,			
							@org_id,			
							@interbranch_flag			


			IF( @result != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 451, 5 ) + ' -- EXIT: '
				RETURN @result
			END
	
			




			INSERT	#gldist
			(
				journal_ctrl_num,			rec_company_code,
				account_code,				description,
				document_1,				document_2,
				reference_code,			balance,
				nat_balance,				nat_cur_code,
				rate,					trx_type,
				seq_ref_id,				balance_oper,
				rate_oper,				rate_type_home,
				rate_type_oper,				org_id
			)
			SELECT	@journal_ctrl_num,			@company_code,
				account_code,				description,
				document_1,				document_2,
				reference_code,			home_balance,
				nat_balance,				nat_cur_code,
				rate_home,				trx_type,
				seq_ref_id,				oper_balance,
				rate_oper,				rate_type_home,			
				rate_type_oper,				org_id
			FROM	#argldist
			WHERE	journal_type = @journal_type

			



			UPDATE	#argldist
			SET	journal_ctrl_num = @journal_ctrl_num
			WHERE	journal_type = @journal_type
	
			



			SELECT	@last_journal_type = @journal_type
			SELECT	@journal_type = NULL		
	
			


			EXEC @result = gltrxcdf_sp	2000, 
							@debug_level 
			IF( @result != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 506, 5 ) + ' -- EXIT: '
			 	RETURN 34563
			END
	
			


			EXEC	@result = gltrxvfy_sp	@journal_ctrl_num,       
								@debug_level            
			IF( @result != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 517, 5 ) + ' -- EXIT: '
				RETURN 34551
			END
		END	
	END	
	ELSE IF EXISTS(SELECT 1 FROM #argldist WHERE trx_type in (2061, 2071))
	BEGIN
	

		SELECT	@last_journal_type = '',
				@journal_type = NULL,
				@last_org_id = '',
				@interbranch_flag = 0

		WHILE(1 = 1)		
		BEGIN
		
			SELECT	@journal_type = MIN(journal_type)
			FROM	#argldist
			WHERE	journal_type > @last_journal_type

			IF( @@error != 0 ) 
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 340, 5 ) + ' -- EXIT: '
				RETURN 34563
			END


			IF( @journal_type IS NULL )
				BREAK

			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 351, 5 ) + ' -- MSG: ' + 'Processing journal_type ' + @journal_type

			WHILE (1 = 1)
			BEGIN

				SELECT	@org_id = MIN(org_id)
				FROM	#argldist
				WHERE	journal_type = @journal_type
				AND		org_id > @last_org_id

				IF( @@error != 0 ) 
				BEGIN
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 345, 5 ) + ' -- EXIT: '
					RETURN 34563
				END

				IF( @org_id IS NULL )
					BREAK

				EXEC @result = gltrxcrh_sp	@process_ctrl_num,		
								-1,		
								2000,	
								2,			
								@journal_type,		
								@journal_ctrl_num OUTPUT,	
								@journal_description,	
								@date_entered,		
								@date_applied,		
								0,				
								0,				
								0,				
								@batch_ctrl_num,		
								0,			
								@company_code,		
								@company_code,		
								@home_cur_code,		
								' ',				
								@trx_type,			
								@user_id,			
								0,				
								@oper_cur_code,		
								@debug_level,			
								@org_id,			
								@interbranch_flag			

	
				IF( @result != 0 )
				BEGIN
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 385, 5 ) + ' -- EXIT: '
					RETURN @result
				END
		
				INSERT	#gldist
				(
					journal_ctrl_num,			rec_company_code,
					account_code,				description,
					document_1,				document_2,
					reference_code,			balance,
					nat_balance,				nat_cur_code,
					rate,					trx_type,
					seq_ref_id,				balance_oper,
					rate_oper,				rate_type_home,
					rate_type_oper,				org_id
				)
				SELECT	@journal_ctrl_num,			@company_code,
					account_code,				description,
					document_1,				document_2,
					reference_code,			home_balance,
					nat_balance,				nat_cur_code,
					rate_home,				trx_type,
					seq_ref_id,				oper_balance,
					rate_oper,				rate_type_home,			
					rate_type_oper,				org_id
				FROM	#argldist
				WHERE	journal_type = @journal_type
				AND		org_id		 = @org_id


				UPDATE	#argldist
				SET	journal_ctrl_num = @journal_ctrl_num
				WHERE	journal_type = @journal_type

				EXEC @result = gltrxcdf_sp	2000, 
							@debug_level 
				IF( @result != 0 )
				BEGIN
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 440, 5 ) + ' -- EXIT: '
				 	RETURN 34563
				END
	
				EXEC	@result = gltrxvfy_sp	@journal_ctrl_num,       
									@debug_level            
				IF( @result != 0 )
				BEGIN
					IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcglt.cpp' + ', line ' + STR( 451, 5 ) + ' -- EXIT: '
					RETURN 34551
				END
			
				SELECT @last_org_id = @org_id,
						@journal_ctrl_num = ''
			END

			SELECT	@last_journal_type = @journal_type
			SELECT	@journal_type = NULL		

		END	


	END

	


	DROP TABLE #gldist

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcglt.cpp', 663, 'Leaving ARCreateGLTransactions_SP', @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCreateGLTransactions_SP] TO [public]
GO
