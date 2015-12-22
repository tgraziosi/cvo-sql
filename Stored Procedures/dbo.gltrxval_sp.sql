SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE        [dbo].[gltrxval_sp]
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
			@oper_rounding_factor	float
			
	IF ( @debug_level > 1 )
	BEGIN
		SELECT  '*****************  Entering gltrxval_sp ******************'
		SELECT  'Originating company: '+@org_company
		SELECT  'Recipient company  : '+@rec_company
		SELECT  'Journal No.        : '+@journal_ctrl_num
		SELECT  'Sequence ID        : '+convert(char(10), @sequence_id )
		SELECT  'Debug Level        : '+convert(char(10), @debug_level )
		SELECT  @work_time = getdate(), @start_time = getdate()
	END
	SELECT  @validate_details_flag = 0,
		@header_only_flag = 0
	
	


	SELECT  @home_currency_code = home_currency,
		@oper_currency_code = oper_currency
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
	
	IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 157, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Preparation Complete'

	IF ( @debug_level > 2 )
	BEGIN
		SELECT	'*** gltrxval_sp - '+convert(char(10),COUNT(*))+
			' transactions to validate'
		FROM	#gltrx
		WHERE	trx_state = -1
		
		SELECT	'*** gltrxval_sp - '+convert(char(10),COUNT(*))+
			' transaction details to validate'
		FROM	#gltrxdet
		WHERE	trx_state = -1
		
	END
	




	IF ( @validate_details_flag = 1 )
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

/*
		UPDATE  #gltrxdet
		SET     mark_flag = 1
		FROM    glcomp_vw c, #gltrxdet t
		WHERE   c.company_code = t.rec_company_code
		AND     t.trx_state = -1
		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			sequence_id, 
			1005 
		FROM    #gltrxdet
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrxdet
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/		
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 205, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate details recipient company code'

		


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

/*
		UPDATE  #gltrxdet
		SET     mark_flag = 1
		FROM    glcomp_vw a, #gltrxdet t
		WHERE   a.company_id = t.company_id
		AND     t.trx_state = -1
		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			sequence_id, 
			1006
		FROM    #gltrxdet
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrxdet
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 233, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate details company ID'

		

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

/*
		UPDATE  #gltrxdet
		SET     mark_flag = 1
		FROM    glchart a, #gltrxdet t
		WHERE   a.account_code = t.account_code
		AND     t.trx_state = -1
		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			sequence_id, 
			1007
		FROM    #gltrxdet
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrxdet
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 261, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate details account code'
		


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


/*
		UPDATE  #gltrxdet
		SET     mark_flag = 1
		FROM    glchart a, #gltrxdet t
		WHERE   a.account_code = t.account_code
		AND     t.trx_state = -1
		AND	(a.currency_code = t.nat_cur_code
		OR	a.currency_code = '')
		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			sequence_id, 
			3021
		FROM    #gltrxdet
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrxdet
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 290, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate currency code against account code'
		


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


/*
		UPDATE  #gltrxdet
		SET     mark_flag = 1
		FROM    glcurr_vw a, #gltrxdet t
		WHERE   a.currency_code = t.nat_cur_code
		AND     t.trx_state = -1

		
        UPDATE  #gltrx
        SET     mark_flag = 1
		FROM    #gltrx t, glcurr_vw c
        WHERE   c.currency_code = t.oper_cur_code
        AND     trx_state = -1

		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			sequence_id, 
			1009
		FROM    #gltrxdet
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrxdet
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 325, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate details natural currency code'
		


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

/*
		UPDATE  #gltrxdet
		SET     mark_flag = 1
		FROM    gltrxtyp a, #gltrxdet t
		WHERE   a.trx_type = t.trx_type
		AND     t.trx_state = -1
		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			sequence_id, 
			1010
		FROM    #gltrxdet
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrxdet
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 352, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate details transaction type'
		




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

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 369, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate operational balance'
	END

	

	
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



/*

	UPDATE  #gltrx
	SET     mark_flag = 1
	FROM    #gltrx h, glprd p, glprd q
	WHERE   h.trx_state = -1
	AND    (h.repeating_flag = 1 
	OR      h.reversing_flag = 1
	OR      h.recurring_flag = 1)
	AND     h.date_applied
	BETWEEN p.period_start_date AND p.period_end_date
	AND     p.period_end_date < q.period_end_date

	


	INSERT  #trxerror (
		journal_ctrl_num,
		sequence_id,
		error_code )
	SELECT  journal_ctrl_num, 
		-1,
		1040
	FROM    #gltrx
	WHERE   (repeating_flag = 1
	OR      reversing_flag = 1)
	AND     mark_flag = 0
	AND     trx_state = -1
	


	UPDATE  #gltrx
	SET     mark_flag = 0
	WHERE   trx_state = -1
*/
	IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 418, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate next fiscal period'
	


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


/*
	UPDATE  #gltrx
	SET     mark_flag = 1
	FROM    #gltrx t, glprd p
	WHERE   t.date_applied BETWEEN p.period_start_date and p.period_end_date
	AND     t.trx_state = -1

	INSERT  #trxerror (     
		journal_ctrl_num, 
		sequence_id, 
		error_code )
	SELECT  journal_ctrl_num, 
		-1, 
		1023
	FROM    #gltrx
	WHERE   mark_flag = 0
	AND     trx_state = -1

	UPDATE  #gltrx
	SET     mark_flag = 0
	WHERE   trx_state = -1
*/
	IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 445, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate apply date'
	



	IF ( @rec_company = @org_company )
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

/*
		UPDATE  #gltrx
		SET     mark_flag = 1
		FROM    gltrxtyp a, #gltrx t
		WHERE   a.trx_type = t.trx_type
		AND     t.trx_state = -1
		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			-1, 
			1010
		FROM    #gltrx
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrx
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 478, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate transaction type'
		


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

/*
		UPDATE  #gltrx
		SET     mark_flag = 1
		FROM    glappid a, #gltrx t
		WHERE   a.app_id = t.app_id
		AND     t.trx_state = -1
		
		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			-1, 
			1003 
		FROM    #gltrx
		WHERE   mark_flag = 0
		AND     trx_state = -1
		
		UPDATE  #gltrx
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 505, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate applications ID'
		




		IF ( @header_only_flag = 0 )
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

			IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 540, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate transaction balance'
		END
		

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


/*
		UPDATE  #gltrx
		SET     mark_flag = 1
		FROM    gljtype a, #gltrx t
		WHERE   a.journal_type = t.journal_type
		AND     t.trx_state = -1

		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			-1, 
			1014
		FROM    #gltrx
		WHERE   mark_flag = 0
		AND     trx_state = -1

		UPDATE  #gltrx
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 568, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate journal type'
		




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

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 585, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate date entered'
		




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

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 602, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate recurring flag'
		




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

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 619, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate repeating flag'
		




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

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 636, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate reversing flag'
		




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

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 653, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate type flag'
		


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

/*
		UPDATE  #gltrx
		SET     mark_flag = 1
		FROM    #gltrx t, glcomp_vw c
		WHERE   t.company_code = c.company_code
		AND     trx_state = -1

		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			-1, 
			1005
		FROM    #gltrx
		WHERE   mark_flag = 0
		AND     trx_state = -1

		UPDATE  #gltrx
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 680, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate transaction company code'
		




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

		UPDATE  #gltrx
		SET     mark_flag = 0
		WHERE   trx_state = -1

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 713, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate transaction home currency'

		

		
		

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

/*

		UPDATE  #gltrx
		SET     mark_flag = 1
		FROM    #gltrx t, glusers_vw c
		WHERE   t.user_id = c.user_id
		AND     trx_state = -1

		INSERT  #trxerror (     
			journal_ctrl_num, 
			sequence_id, 
			error_code )
		SELECT  journal_ctrl_num, 
			-1, 
			1028
		FROM    #gltrx
		WHERE   mark_flag = 0
		AND     trx_state = -1

		UPDATE  #gltrx
		SET     mark_flag = 0
		WHERE   trx_state = -1
*/
		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 751, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate transaction user ID'
		




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

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 768, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Validate transaction hold flag'
		



		






		UPDATE  #gltrx
		SET     intercompany_flag = 1
		FROM    #gltrx h, #gltrxdet d
		WHERE   h.journal_ctrl_num = d.journal_ctrl_num
		AND     h.company_code != d.rec_company_code
		




		EXEC    @result = gltrxoff_sp   @org_company,
						@debug_level

		IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 793, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Create offset records for I/C transactions'

		IF ( @result != 0 )
			return @result
	END
	






	


	EXEC    @result = gltrxusl_sp   @org_company,
					@rec_company




	IF ( @debug_level > 2 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 814, 5 ) + ' -- MSG: ' + CONVERT(char,@work_time,100) + 'Perform user supplied processing'
	








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
	
	IF ( @debug_level > 1 ) SELECT 'gltrxval.cpp' + ', line ' + STR( 858, 5 ) + ' -- MSG: ' + CONVERT(char,@start_time,100) + '*****************  Exiting ******************'
	




	IF EXISTS(      SELECT  *
			FROM    #trxerror ) OR @result != 0
	BEGIN
			
		IF ( @debug_level > 1 )
		BEGIN
			SELECT  '*** gltrxval_sp - Errors Found!'
			SELECT  convert( char(20), 'journal_ctrl_num' )+
				convert( char(15), 'sequence_id' )+
				convert( char(15), 'Description' )
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
			SELECT  ' *** No Errors found in gltrxval_sp'
		END
		RETURN  0
	END

END




GO
GRANT EXECUTE ON  [dbo].[gltrxval_sp] TO [public]
GO
