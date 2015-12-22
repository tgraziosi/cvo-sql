SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE        [dbo].[gltrxval1_sp]
			@org_company            varchar(8),
			@rec_company            varchar(8),
			@journal_ctrl_num       varchar(16) = NULL,
			@sequence_id            int = NULL,
			@debug_level                  smallint = 0
			
AS

BEGIN

	DECLARE         @result                 int,
			@home_currency_code     varchar(8),
			@prec                   int,
			@rounding_factor        float,
			@validate_details_flag  smallint,
			@header_only_flag       smallint,
			@work_time              datetime,
			@start_time             datetime,
			
			@oper_currency_code	varchar(8),
			@oper_prec		int,
			@oper_rounding_factor	float,
			@ib_flag		int,
			@current_period_end_date int,
			@error_level		 int,
			@error_code		 int,
			@db_name                 varchar(128)

	IF ( @debug_level > 1 )
	BEGIN
		SELECT  "*****************  Entering gltrxval_sp ******************"
		SELECT  "Originating company: "+@org_company
		SELECT  "Recipient company  : "+@rec_company
		SELECT  "Journal No.        : "+@journal_ctrl_num
		SELECT  "Sequence ID        : "+convert(char(10), @sequence_id )
		SELECT  "Debug Level        : "+convert(char(10), @debug_level )
		SELECT  @work_time = getdate(), @start_time = getdate()
	END
	SELECT  @validate_details_flag = 0,
		@header_only_flag = 0
	
	


	SELECT  @home_currency_code = home_currency,
		@oper_currency_code = oper_currency,
		@current_period_end_date = period_end_date 
	FROM    glco


	


	SELECT  @rounding_factor = rounding_factor,
		@prec = curr_precision
	FROM    glcurr_vw
	WHERE   currency_code = @home_currency_code

	SELECT  @oper_rounding_factor = rounding_factor,
		@oper_prec = curr_precision
	FROM    glcurr_vw
	WHERE   currency_code = @oper_currency_code

	IF ( @rounding_factor IS NULL OR @prec IS NULL 
	OR   @oper_rounding_factor IS NULL OR @oper_prec IS NULL )
	BEGIN
		RETURN 1050
	END
	





	IF ( @journal_ctrl_num IS NOT NULL )
	BEGIN
		UPDATE  #gltrx
		SET     trx_state = -1
		WHERE   journal_ctrl_num = @journal_ctrl_num
		
		SELECT  @header_only_flag = 1
		


		IF ( @sequence_id IS NOT NULL )
		BEGIN
			UPDATE  #gltrxdet
			SET     trx_state = -1
			WHERE   journal_ctrl_num = @journal_ctrl_num
			AND     sequence_id = @sequence_id
			
			SELECT  @validate_details_flag = 1
		END

	END
	



	ELSE
	BEGIN
		UPDATE  #gltrx
		SET     trx_state = -1
		WHERE   trx_state = 0
		AND     company_code = @org_company
		
		UPDATE  #gltrxdet
		SET     trx_state = -1
		WHERE   trx_state = 0
		AND     rec_company_code = @rec_company
		
		SELECT  @validate_details_flag = 1
	END
	
	IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 167, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Preparation Complete"

	IF ( @debug_level > 2 )
	BEGIN
		SELECT	"*** gltrxval_sp - "+convert(char(10),COUNT(*))+
			" transactions to validate"
		FROM	#gltrx
		WHERE	trx_state = -1
		
		SELECT	"*** gltrxval_sp - "+convert(char(10),COUNT(*))+
			" transaction details to validate"
		FROM	#gltrxdet
		WHERE	trx_state = -1
		
	END
	




	IF ( @validate_details_flag = 1 )
	BEGIN
		




		
		SELECT @error_code = 1005
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
		        INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				sequence_id, 
				1005 
			FROM    #gltrxdet t
			WHERE   not exists( select 1 from  glcomp_vw c where t.rec_company_code = c.company_code )
			AND     trx_state = -1
		END

		










































		
		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 256, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details recipient company code"

		




		SELECT @error_code = 1006
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				sequence_id, 
				1006
			FROM    #gltrxdet t
			WHERE   not exists( select 1 from  glcomp_vw c where c.company_id = t.company_id )
			AND     trx_state = -1
		END
		




















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 300, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details company ID"

		




		SELECT @error_code = 1007
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				sequence_id, 
				1007
			FROM    #gltrxdet t
			WHERE   not exists(select 1 from glchart where t.account_code = glchart.account_code)
			AND     trx_state = -1
		END
		




















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 344, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details account code"
		




		SELECT @error_code = 3021
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				sequence_id, 
				3021
			FROM    #gltrxdet t, glchart a
			WHERE   a.account_code = t.account_code
			AND	(a.currency_code <> t.nat_cur_code
			AND	a.currency_code <> '')
			AND     trx_state = -1
		END
		






















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 391, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate currency code against account code"
		




		SELECT @error_code = 1009
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				sequence_id, 
				1009
			FROM    #gltrxdet t 
			WHERE   not exists(select 1 from glcurr_vw a where a.currency_code = t.nat_cur_code)
			AND     trx_state = -1
		END
		





		
       





















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 442, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details natural currency code"
		




		SELECT @error_code = 1010
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				sequence_id, 
				1010
			FROM    #gltrxdet t
			WHERE   not exists(select 1 from gltrxtyp a where a.trx_type = t.trx_type)
			AND     trx_state = -1
		END
		




















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 485, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate details transaction type"
		




		SELECT @error_code = 3025
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				sequence_id, 
				3025
			FROM    #gltrxdet
			WHERE   balance_oper IS NULL
			AND     trx_state = -1
		END
		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 507, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate operational balance"
	END

	




	
	


	



	SELECT @error_code = 1040
	EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
	IF (@error_level > 2)
	BEGIN	
		INSERT  #trxerror (
			journal_ctrl_num,
			sequence_id,
			error_code )
		SELECT  journal_ctrl_num, 
			-1,
			1040
		FROM    #gltrx h, glprd p
		WHERE   h.date_applied
		BETWEEN p.period_start_date AND p.period_end_date
		AND not exists(select 1 from glprd q where p.period_end_date+1 = q.period_start_date)
		AND    (repeating_flag = 1
		OR      reversing_flag = 1 
		OR      h.recurring_flag = 1 )
		AND     trx_state = -1
	END

	










	


	











	


	



	IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 578, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate next fiscal period"
	




	SELECT @error_code = 1023
	EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
	IF (@error_level > 2)
	BEGIN	
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			-1, 
			1023
		FROM    #gltrx t
		WHERE   not exists(select 1 from glprd p where t.date_applied BETWEEN p.period_start_date and p.period_end_date)
		AND     trx_state = -1
	END
	





















	IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 622, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate apply date"
	



	IF ( @rec_company = @org_company )
	BEGIN
		




		SELECT @error_code = 1010
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1010
			FROM    #gltrx t
			WHERE   not exists(select 1 from gltrxtyp a where a.trx_type = t.trx_type )
			AND     trx_state = -1
		END
		




















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 671, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction type"
		




		SELECT @error_code = 1003
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1003 
			FROM    #gltrx t
			WHERE   not exists(select 1 from glappid a where a.app_id = t.app_id)
			AND     trx_state = -1
		END
		




















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 714, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate applications ID"
		




		IF ( @header_only_flag = 0 )
		BEGIN
			


			









			SELECT @error_code = 1013
			EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
			IF (@error_level > 2)
			BEGIN	
				INSERT          #trxerror (
						journal_ctrl_num,
						sequence_id,
						error_code )
				SELECT          d.journal_ctrl_num,
						-1, 
						1013
				FROM            #gltrxdet d, #gltrx h
				WHERE           h.trx_state = -1
				AND             h.journal_ctrl_num = d.journal_ctrl_num
				GROUP BY        d.journal_ctrl_num 
				HAVING          ABS(SUM((SIGN(balance) * ROUND(ABS(balance) + 0.0000001, @prec)))) >= @rounding_factor
				OR	        ABS(SUM((SIGN(balance_oper) * ROUND(ABS(balance_oper) + 0.0000001, @oper_prec)))) >= @oper_rounding_factor
			END

			IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 755, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction balance"
		END
		






		SELECT @error_code = 1014
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1014
			FROM    #gltrx t
			WHERE   not exists(select 1 from gljtype a where a.journal_type = t.journal_type)
			AND     trx_state = -1
		END

		





















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 803, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate journal type"
		




		SELECT @error_code = 1022
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1022
			FROM    #gltrx
			WHERE   date_entered <= 0
			AND     trx_state = -1
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 826, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate date entered"
		




		SELECT @error_code = 1024
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN

			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1024
			FROM    #gltrx
			WHERE   recurring_flag NOT IN ( 0, 1 )
			AND     trx_state = -1
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 850, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate recurring flag"
		




		SELECT @error_code = 1025
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN

			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1025
			FROM    #gltrx
			WHERE   repeating_flag NOT IN ( 0, 1 )
			AND     trx_state = -1
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 874, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate repeating flag"
		




		SELECT @error_code = 1026
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN

			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1026
			FROM    #gltrx
			WHERE   reversing_flag NOT IN ( 0, 1 )
			AND     trx_state = -1
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 898, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate reversing flag"
		




		SELECT @error_code = 1027
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1027
			FROM    #gltrx
			WHERE   type_flag NOT BETWEEN 0 AND 6
			AND     trx_state = -1
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 921, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate type flag"
		




		SELECT @error_code = 1005
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1005
			FROM    #gltrx t
			WHERE   not exists(select 1 from glcomp_vw c where t.company_code = c.company_code)
			AND     trx_state = -1
		END

		




















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 965, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction company code"
		




		UPDATE  #gltrx
		SET     mark_flag = 1
		FROM    #gltrx t, glcurr_vw c
		WHERE   c.currency_code = t.home_cur_code
		AND     trx_state = -1
		
		UPDATE  #gltrx
		SET     mark_flag = 1
		FROM    #gltrx t, glcurr_vw c
		WHERE   c.currency_code = t.oper_cur_code
		AND     trx_state = -1

		SELECT @error_code = 1050
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1050
			FROM    #gltrx
			WHERE   mark_flag = 0
			AND     trx_state = -1
		END

		UPDATE  #gltrx
		SET     mark_flag = 0
		WHERE   trx_state = -1

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1004, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction home currency"

		










		




		SELECT @error_code = 1028
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1028
			FROM    #gltrx t
			WHERE   not exists(select 1 from glusers_vw c where t.user_id = c.user_id)
			AND     trx_state = -1
		END

		




















		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1060, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction user ID"
		




		SELECT @error_code = 1029
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  journal_ctrl_num, 
				-1, 
				1029
			FROM    #gltrx
			WHERE   hold_flag NOT IN ( 0, 1 )
			AND     trx_state = -1
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1083, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Validate transaction hold flag"
		



		






		UPDATE  #gltrx
		SET     intercompany_flag = 1
		FROM    #gltrx h, #gltrxdet d
		WHERE   h.journal_ctrl_num = d.journal_ctrl_num
		AND     h.company_code != d.rec_company_code
		




		EXEC    @result = gltrxoff1_sp   @org_company,
						@debug_level

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1108, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Create offset records for I/C transactions"

		IF ( @result != 0 )
			return @result
	END
	

		select @db_name = db_name from  glcomp_vw WHERE	company_code = @rec_company

		
		
		


		SELECT @error_code = 2039
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			












			exec ('INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  dt.journal_ctrl_num, 
				sequence_id, 
				2039
			FROM    #gltrxdet dt
				INNER JOIN #gltrx t ON dt.journal_ctrl_num = t.journal_ctrl_num
			WHERE   sequence_id > -1
			AND     t.home_cur_code NOT IN
		       		(SELECT currency_code FROM  ' + @db_name + ' ..glcurr_vw)
			AND     dt.trx_state = -1 AND rec_company_code =''' + @rec_company + '''')
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1155, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Invalid home currency"



		



		

		


			SELECT @ib_flag = 0
			SELECT @ib_flag = ib_flag
			FROM glco
			
			
			IF @ib_flag > 0
			BEGIN



				

 
				SELECT @error_code = 2048
				EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
					IF (@error_level > 2)
					BEGIN		
						












						exec('INSERT  #trxerror (     
						journal_ctrl_num, 
						sequence_id, 
						error_code )
						SELECT  dt.journal_ctrl_num, 
							sequence_id, 
							2048
						FROM    #gltrxdet dt
							INNER JOIN #gltrx t ON dt.journal_ctrl_num = t.journal_ctrl_num
							LEFT JOIN ' + @db_name + '..Organization org ON dt.org_id	= org.organization_id AND org.active_flag = 1
						WHERE   org.organization_id IS NULL	
						AND     dt.trx_state = -1 AND dt.trx_state = -1 AND rec_company_code =''' + @rec_company + '''' )
						
						
					END
				

				IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1216, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "The organization in detail is invalid"

		

 
			
			SELECT @error_code = 2051
			EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
			IF (@error_level > 2)
			BEGIN	
				INSERT  #trxerror (     
					journal_ctrl_num, 
					sequence_id, 
					error_code )
				SELECT  dt.journal_ctrl_num, 
					0, 
					2051
				FROM    #gltrxdet dt
					INNER JOIN #gltrx t ON dt.journal_ctrl_num = t.journal_ctrl_num
				WHERE 	t.company_code = dt.rec_company_code 
				AND 	sequence_id != -1
				AND     t.org_id <> dt.org_id
				AND     interbranch_flag != 1

				
			END

			IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1244, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Inter-Organization transactions must have IO flag turned on"

		       END


		


		
		SELECT @error_code = 2016
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			













			exec('INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
				SELECT  dt.journal_ctrl_num, 
					0, 
					2016
				FROM    #gltrxdet dt
					INNER JOIN #gltrx t ON dt.journal_ctrl_num = t.journal_ctrl_num
					INNER JOIN ' + @db_name + '..glchart ch ON dt.account_code = ch.account_code
				WHERE   ((t.date_applied NOT BETWEEN active_date AND inactive_date
	    				AND (active_date > 0 AND inactive_date > 0))
	    				OR (t.date_applied < active_date AND inactive_date = 0))
					AND rec_company_code = ''' + @rec_company + '''' )
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1288, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Account code dates"

		


		
		SELECT @error_code = 2017
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			











			exec('INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  dt.journal_ctrl_num, 
				0, 
				2017  
			FROM    #gltrxdet dt
				INNER JOIN #gltrx t ON dt.journal_ctrl_num = t.journal_ctrl_num
				INNER JOIN ' + @db_name + '..glchart ch ON dt.account_code = ch.account_code
			WHERE   inactive_flag = 1 AND rec_company_code =''' + @rec_company + '''' )	
		END

		
		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1325, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Inactive account."

		


		


		














		


		

		










		
		SELECT @error_code = 2024
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN	
			









			exec('INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  t.journal_ctrl_num, 
				0, 
				2024 
			FROM   #gltrx t
			       INNER JOIN ' + @db_name + '..glprd prd ON t.date_applied < prd.period_start_date AND prd.period_end_date = @current_period_end_date AND rec_company_code =''' + @rec_company + '' )
		END
	
		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1391, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Check for prior period / future period posting"


		
		










		
		SELECT @error_code = 2027
		EXEC    glerrdef1_sp @error_code, @error_level OUTPUT
					
		IF (@error_level > 2)
		BEGIN
			









			exec('INSERT  #trxerror (     
				journal_ctrl_num, 
				sequence_id, 
				error_code )
			SELECT  t.journal_ctrl_num, 
				0, 
				2027  
			FROM    #gltrx t
				INNER JOIN ' + @db_name + '..glprd prd ON t.date_applied > prd.period_end_date AND prd.period_end_date = @current_period_end_date AND rec_company_code =''' + @rec_company + '''')
		END

		IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1433, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Check for prior period / future period posting"
		

			


	









	EXEC    @result = gltrxusl_sp   @org_company,
					@rec_company




	IF ( @debug_level > 2 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1455, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Perform user supplied processing"
	








	IF ( @rec_company = @org_company )
	BEGIN
		









		UPDATE  #gltrx
		SET     trx_state = 3
		FROM    #gltrx t, #trxerror e
		WHERE   t.journal_ctrl_num = e.journal_ctrl_num
		AND     trx_state = -1
		
		UPDATE  #gltrx
		SET     trx_state = 2
		WHERE   trx_state = -1
		
		UPDATE  #gltrxdet
		SET     trx_state = 0
	     	WHERE   trx_state = -1
	END
	
	ELSE
	BEGIN
		UPDATE  #gltrxdet
		SET     trx_state = 0
	     	WHERE   trx_state = -1
	END		
	
	IF ( @debug_level > 1 ) SELECT "gltrxval1.cpp" + ", line " + STR( 1499, 5 ) + " -- MSG: " + CONVERT(char,@start_time,100) + "*****************  Exiting ******************"
	




	IF EXISTS(      SELECT  *
			FROM    #trxerror ) OR @result != 0
	BEGIN
			
		IF ( @debug_level > 1 )
		BEGIN
			SELECT  "*** gltrxval_sp - Errors Found!"
			SELECT  convert( char(20), "journal_ctrl_num" )+
				convert( char(15), "sequence_id" )+
				convert( char(15), "Description" )
			SELECT  convert( char(20), journal_ctrl_num )+
				convert( char(15), sequence_id )+
				e_ldesc
			FROM    #trxerror t, glerrdef e
			WHERE	t.error_code = e.e_code
		END
	   
		RETURN  1056
	END
	
	ELSE
	BEGIN
		IF ( @debug_level > 1 )
		BEGIN
			SELECT  " *** No Errors found in gltrxval_sp"
		END
		RETURN  0
	END

END

GO
GRANT EXECUTE ON  [dbo].[gltrxval1_sp] TO [public]
GO
