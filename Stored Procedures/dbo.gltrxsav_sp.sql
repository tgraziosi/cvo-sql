SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                




CREATE PROCEDURE [dbo].[gltrxsav_sp] 	@process_ctrl_num varchar(16),
				@org_company varchar(8),
				@debug SMALLINT = 0,
				@interface_flag SMALLINT = 0,
				@userid INT = 0
AS

BEGIN

	DECLARE @tran_started           smallint,
		@batch_date_applied     int,
		@batch_source           varchar(16),
		@result                 int,
		@new_batch_code         varchar(16),
		@process_user_id        smallint,
		@process_state          smallint,
		@process_parent_app     smallint,
		@process_parent_company varchar(8),
		@prec                   smallint,
		@rounding_factor        float,
		@prec1       		smallint,
		@rounding_factor1  	float,	



		@actual_number		int,
		@actual_total		float,


		@org_id			varchar(30)  

CREATE TABLE #batches
(
	date_applied		int NOT NULL,
	source_batch_code	varchar(16) NOT NULL, 
	org_id			varchar(30) NULL
)

	IF ( @debug > 0 )
		SELECT  "*** gltrxsav_sp - Entering gltrxsav_sp"
	
	SELECT  @tran_started = 0
	
	

	IF ( @org_company IS NULL )
		RETURN  1066
	ELSE IF NOT EXISTS(     SELECT  company_code
				FROM    glcomp_vw
				WHERE   company_code = @org_company )
		RETURN  1005
	


	EXEC    @result = pctrlget_sp   @process_ctrl_num,
					@process_state OUTPUT,
					@process_user_id OUTPUT,
					@process_parent_app OUTPUT,
					@process_parent_company OUTPUT
	
	IF ( @result != 0 )
	BEGIN
		IF ( @debug > 0 )
			SELECT  "*** gltrxsav_sp - Invalid process key"
		RETURN 1057
	END
	



	IF EXISTS(      SELECT  1
			FROM    glco
			WHERE   batch_proc_flag = 1 )
	BEGIN
		INSERT  #batches (      date_applied,
					source_batch_code,
					org_id )  
		SELECT  DISTINCT        date_applied, 
					source_batch_code,
					org_id  
		FROM    #gltrx
		WHERE   RTRIM(batch_code) = ""
		OR      RTRIM(batch_code) IS NULL
	END
	




	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRANSACTION
		SELECT  @tran_started = 1
	END
	
	
	IF ( @debug > 3 )
	BEGIN 
	    SELECT 'gltrxsav_sp -  *** #gltrx   '
	    SELECT 'batch code ' + ' journal_ctrl_num ' + ' Date applied ' + ' source_batch ' + 'Organization ' +  ' mark flag' + ' Company Code'
	    SELECT CONVERT(char(17), batch_code ) + ' ' + CONVERT(char(20) , journal_ctrl_num)+ ' ' + CONVERT ( char(12 ), date_applied )  + ' ' + CONVERT (char(20), source_batch_code ) 
		   + ' ' + CONVERT (char(30) , org_id )  
		   + ' ' + CONVERT (char(10), mark_flag ) + ' ' + CONVERT( char(10), company_code)
		   FROM #gltrx

	    SELECT 'gltrxsav_sp -  *** #gltrxdet'
	    SELECT  'Detail  Journal Ctrl ' + ' ' + 'rate oper ' + ' ' + 'balance oper ' + 
			'   balance  '  + 
			' rec company ' + ' ' +  ' account_code ' + ' rec org_id '

	    SELECT  convert( char(20), journal_ctrl_num )+ ' ' +
			convert( char(10), rate_oper )+ ' ' +
			convert( char(20), balance_oper ) + ' ' +
			convert( char(20), balance ) + ' ' +
			convert( char(10), rec_company_code )+ ' ' +
			convert( char(10), account_code )+ ' ' +
			convert( char(30), org_id  )
		FROM 	#gltrxdet		    


	END
	
	
	



	IF EXISTS(      SELECT  1
			FROM    glco
			WHERE   batch_proc_flag = 1 )
	BEGIN
		WHILE 1=1
		BEGIN
			SELECT  @batch_date_applied = NULL
			SELECT  @batch_date_applied = MIN( date_applied )
			FROM    #batches
			
			IF ( @batch_date_applied IS NULL )
				break
			
			SELECT  @batch_source = MIN( source_batch_code )
			FROM    #batches
			WHERE   date_applied = @batch_date_applied
			
			SELECT  @org_id = org_id    
			FROM    #batches
			WHERE   date_applied = @batch_date_applied
			   and  source_batch_code =  @batch_source
			
			
			
			
			EXEC    @result = gltrxbat_sp   @new_batch_code OUTPUT,
							@batch_source,
							6010,
							@process_user_id,
							@batch_date_applied,
							@org_company,
							@org_id   
							
			IF ( @result != 0 )
				RETURN  @result
				
			UPDATE  batchctl
			SET     process_group_num = @process_ctrl_num
			WHERE   batch_ctrl_num = @new_batch_code
				
			UPDATE  #gltrx
			SET     batch_code = @new_batch_code
			WHERE   date_applied = @batch_date_applied
			AND     source_batch_code = @batch_source
			AND     org_id = @org_id	-- Rev 3.1
			AND     RTRIM(batch_code) = ""
			OR      RTRIM(batch_code) IS NULL
			
			DELETE  #batches
			WHERE   date_applied = @batch_date_applied
			AND     source_batch_code = @batch_source
			AND     org_id = @org_id   


			
			SELECT 	@actual_number = count(*)
			FROM 	#gltrx
			WHERE	batch_code = @new_batch_code
		
			SELECT	@actual_total = sum(abs(d.balance))/2
			FROM    #gltrxdet d, #gltrx h, glcurr_vw c
			WHERE   h.trx_state = 2
			AND     h.journal_ctrl_num = d.journal_ctrl_num
			AND     d.nat_cur_code = c.currency_code
			AND     h.batch_code = @new_batch_code
			
			UPDATE	batchctl
			SET	actual_number = ISNULL(@actual_number, 0 )  ,
				actual_total  = ISNULL(@actual_total, 0.0)
			WHERE	batch_ctrl_num = @new_batch_code

			

			
			IF ( @debug > 3 )
			BEGIN
				SELECT  "*** gltrxsav_sp - Created batch "+
					@new_batch_code+" for process "+
					@process_ctrl_num
					
				SELECT  "*** gltrxsav_sp - Number of transactions "+
					"in batch "+@new_batch_code+" = "+
					convert(char(10),COUNT(*))
				FROM    #gltrx
				WHERE   batch_code = @new_batch_code
			END
		END
		
	END


	IF ( @debug > 3 )
	BEGIN 
	    SELECT 'gltrxsav_sp -  *** #gltrx   '
	    SELECT 'batch code ' + ' journal_ctrl_num ' + ' Date applied ' + ' source_batch ' + 'Organization ' +  ' mark flag' + ' Company Code'
	    SELECT CONVERT(char(17), batch_code ) + ' ' + CONVERT(char(20) , journal_ctrl_num)+ ' ' + CONVERT ( char(12 ), date_applied )  + ' ' + CONVERT (char(20), source_batch_code ) 
		   + ' ' + CONVERT (char(30) , org_id )  
		   + ' ' + CONVERT (char(10), mark_flag ) + ' ' + CONVERT( char(10), company_code)
		   FROM #gltrx

	    SELECT 'gltrxsav_sp -  *** #gltrxdet'
	    SELECT  'Detail  Journal Ctrl ' + ' ' + 'rate oper ' + ' ' + 'balance oper ' + 
			'   balance  '  + 
			' rec company ' + ' ' +  ' account_code ' + ' rec org_id '

	    SELECT  convert( char(20), journal_ctrl_num )+ ' ' +
			convert( char(10), rate_oper )+ ' ' +
			convert( char(20), balance_oper ) + ' ' +
			convert( char(20), balance ) + ' ' +
			convert( char(10), rec_company_code )+ ' ' +
			convert( char(10), account_code )+ ' ' +
			convert( char(30), org_id  )
		FROM 	#gltrxdet		    


	END




	INSERT  gltrx ( timestamp,
			journal_type,
			journal_ctrl_num,
			journal_description,
			date_entered,
			date_applied,
			recurring_flag,
			repeating_flag,
			reversing_flag,
			hold_flag,
			posted_flag,
			date_posted,
			source_batch_code,
			batch_code,
			type_flag,
			intercompany_flag,
			company_code,
			app_id,
			home_cur_code,
			document_1,
			trx_type,
			user_id,
			source_company_code,
			process_group_num ,
			oper_cur_code,
			org_id,
			interbranch_flag
			)
			
	SELECT          NULL,
			journal_type,
			journal_ctrl_num,
			journal_description,
			date_entered,
			date_applied,
			recurring_flag,
			repeating_flag,
			reversing_flag,
			hold_flag,
			posted_flag,
			date_posted,
			source_batch_code,
			batch_code,
			type_flag,
			intercompany_flag,
			company_code,
			app_id,
			home_cur_code,
			document_1,
			trx_type,
			user_id,
			source_company_code,
			process_group_num,
			oper_cur_code,
			org_id,
			interbranch_flag
	FROM    #gltrx
	WHERE   trx_state = 2
	AND type_flag != 6

	IF ( @@error != 0 )
	BEGIN
		IF ( @tran_started = 1 )
			rollback transaction
		IF ( @debug > 0 )
			SELECT  "*** gltrxsav_sp - Database Error saving transactions!"
		RETURN  1039
	END

	




	INSERT ibifc (	id,		date_entered,		date_applied,	controlling_org_id,	detail_org_id,
			amount,		currency_code,		tax_code,	state_flag,		trx_type,		
			link1,		link2,			username)
	SELECT		newid(), 	dateadd(day, date_entered - 693596, '01/01/1900'),		dateadd(day,date_applied-693596, '01/01/1900'), 	
										'',			'',
			0,		home_cur_code,		'',		0,			trx_type , 			
			journal_ctrl_num, '' ,	SYSTEM_USER
	FROM    #gltrx
	WHERE   trx_state = 2
	AND 	type_flag != 6
	AND	interbranch_flag = 1
	

	


	SELECT  @rounding_factor = rounding_factor,
		@prec = curr_precision
	FROM    glcurr_vw c, glco h
	WHERE   c.currency_code = h.home_currency

	SELECT   @rounding_factor1 = rounding_factor,
		 @prec1 = curr_precision
	FROM    glcurr_vw c, glco h
	WHERE c.currency_code = h.oper_currency

	IF ( @rounding_factor IS NULL OR @prec IS NULL 
	     OR 
	     @rounding_factor1 = NULL OR @prec1 IS NULL
	)
	BEGIN
		RETURN 1050
	END
	


	INSERT  gltrxdet (
		timestamp,
		journal_ctrl_num,
		sequence_id,
		rec_company_code,
		company_id,
		account_code,
		description,
		document_1,
		document_2,
		reference_code,
		balance,
		nat_balance,
		nat_cur_code,
		rate,
		posted_flag,
		date_posted,
		trx_type,
		offset_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		seq_ref_id, 
		balance_oper,
		rate_oper,
		rate_type_home,
		rate_type_oper,
		org_id
		)
			
	SELECT  NULL,
		d.journal_ctrl_num,
		d.sequence_id,
		d.rec_company_code,
		d.company_id,
		d.account_code,
		d.description,
		d.document_1,
		d.document_2,
		d.reference_code,
		ROUND( d.balance, @prec ),
		ROUND( d.nat_balance, c.curr_precision ),
		d.nat_cur_code,
		d.rate,
		d.posted_flag,
		d.date_posted,
		d.trx_type,
		d.offset_flag,
		d.seg1_code,
		d.seg2_code,
		d.seg3_code,
		d.seg4_code,
		d.seq_ref_id,
		ROUND( d.balance_oper, @prec1 ),
		d.rate_oper,
		d.rate_type_home,
		d.rate_type_oper,
		d.org_id
	FROM    #gltrxdet d, #gltrx h, glcurr_vw c
	WHERE   h.trx_state = 2
	AND     h.journal_ctrl_num = d.journal_ctrl_num
	AND     d.nat_cur_code = c.currency_code



	IF ( @@error != 0 )
	BEGIN
		IF ( @tran_started = 1 )
			rollback transaction
		IF ( @debug > 0 )
			SELECT  "*** gltrxsav_sp - Database Error saving details!"
		RETURN  1039
	END

	


	














	



	






    EXEC @result = gltrxusv_sp @org_company, 
                               @debug, 
                               @interface_flag, 
                               @userid
	
	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
			ROLLBACK TRAN
		RETURN  -1
	END
	


	TRUNCATE TABLE #gltrx
	TRUNCATE TABLE #gltrxdet
		
	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRANSACTION
		SELECT  @tran_started = 0
	END
	




	IF ( @debug > 0 )
		SELECT  "*** gltrxsav_sp - Transaction Save Successfull"
		
	RETURN @result
END

GO
GRANT EXECUTE ON  [dbo].[gltrxsav_sp] TO [public]
GO
