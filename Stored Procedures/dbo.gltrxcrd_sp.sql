SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[gltrxcrd_sp]	@module_id	  	int,
					@interface_mode	smallint,
					@journal_ctrl_num 	varchar(30),     
					@sequence_id		int OUTPUT,
					@rec_company_code 	varchar(8),
					@account_code	  	varchar(32),
					@description	  	varchar(40),
					@document_1	  	varchar(16),
					@document_2	  	varchar(16),
					@reference_code	varchar(32),
					@balance	  	float,
					@nat_balance	  	float,
					@nat_cur_code	  	varchar(8),
					@rate		  	float,
					@trx_type	  	smallint,
					@seq_ref_id	  	int,
					@balance_oper		float = NULL,
					@rate_oper		float = NULL,
					@rate_type_home	varchar(8) = NULL,
					@rate_type_oper      varchar(8) = NULL,
					@debug			smallint = 0,
					@ib_org_id		varchar(30)=NULL

AS
BEGIN

	DECLARE	@result		int, 
			@insert_required	smallint,
			@home_company		varchar(8),
			@company_id		smallint,
			@update_seq_id	int,
			@account_format_mask varchar(35),
			@seg1_code		varchar(16),
			@seg2_code		varchar(16),
			@seg3_code		varchar(16),
			@seg4_code		varchar(16),
			@home_currency_code	varchar(8),
			@oper_currency_code	varchar(8),
			@oper_rate_type	varchar(8),
			@home_rate_type	varchar(8),
			@date_applied		int,
			@oper_prec		int,
			@rate_used		float
		
	IF ( @debug > 0 )
		SELECT	'*** gltrxcrd_sp - Entering gltrxcrd_sp'
		



	


	IF ( @interface_mode NOT IN ( 1, 2 ) )
	BEGIN	
		IF ( @debug > 0 )
			SELECT	'*** gltrxcrd_sp - Invalid Interface mode detected'
		RETURN 1054
	END

	


	SELECT 	@account_format_mask = account_format_mask
	FROM	glcomp_vw
	WHERE	company_code = @rec_company_code
	


	SELECT	@home_company = company_code,
		@date_applied = date_applied
	FROM	#gltrx
	WHERE	journal_ctrl_num = @journal_ctrl_num
	
	IF( @rate_oper IS NULL )
	BEGIN
		SELECT	@home_currency_code = home_currency,
			@oper_currency_code = oper_currency,
			@oper_rate_type = rate_type_oper,
			@home_rate_type = rate_type_home
		FROM glco

		SELECT @oper_prec = curr_precision
		FROM    glcurr_vw
		WHERE   currency_code = @oper_currency_code

		EXEC @result = CVO_Control..mccurate_sp 	@date_applied, 
				@home_currency_code, @oper_currency_code,
				@oper_rate_type, @rate_used OUTPUT, 0
	
		IF ( @result != 0)
		BEGIN
			IF ( @debug > 0 )
				SELECT	'*** gltrxcrd_sp - Could not get Exchange Rate'
			RETURN 3022
		END
	
		IF (@rate_oper IS NULL)
		BEGIN
			SELECT @rate_oper = @rate_used
			SELECT @rate_type_oper = @oper_rate_type
			SELECT @rate_type_home = @home_rate_type
			SELECT @balance_oper =  (SIGN(@balance * ( SIGN(1 + SIGN(@rate_used))*(@rate_used) + (SIGN(ABS(SIGN(ROUND(@rate_used,6))))/(@rate_used + SIGN(1 - ABS(SIGN(ROUND(@rate_used,6)))))) * SIGN(SIGN(@rate_used) - 1) )) * ROUND(ABS(@balance * ( SIGN(1 + SIGN(@rate_used))*(@rate_used) + (SIGN(ABS(SIGN(ROUND(@rate_used,6))))/(@rate_used + SIGN(1 - ABS(SIGN(ROUND(@rate_used,6)))))) * SIGN(SIGN(@rate_used) - 1) )) + 0.0000001, @oper_prec))
		END
	END

	


	EXEC @result = glprsact_sp	@account_code, 
					@account_format_mask,
					@seg1_code = @seg1_code OUTPUT,
					@seg2_code = @seg2_code OUTPUT,                  
					@seg3_code = @seg3_code OUTPUT,                  
					@seg4_code = @seg4_code OUTPUT

	IF ( @result != 0)
	BEGIN
		IF ( @debug > 0 )
			SELECT	'*** gltrxcrd_sp - Could not parse account code'
		RETURN @result
	END
	

	SELECT	@company_id = company_id 
	FROM	glcomp_vw
	WHERE	company_code = @rec_company_code

	IF ( @company_id = 0 )
	BEGIN
		IF ( @debug > 0 )
			SELECT	'*** gltrxcrd_sp - Could not get company code'
		RETURN	1005
	END
	
















	



	SELECT	@insert_required = 1
	


	IF 	(@rec_company_code = @home_company)
	  AND
		EXISTS(	SELECT	*  
			FROM	glacsum 
			WHERE   account_code = @account_code 
			AND     app_id = @module_id )
	BEGIN
		
		SELECT	@update_seq_id = NULL

		SELECT	@update_seq_id = sequence_id 
		FROM	#gltrxdet        
		WHERE	journal_ctrl_num = @journal_ctrl_num
		AND	account_code = @account_code 
		AND	rec_company_code = @rec_company_code 
		AND	reference_code = @reference_code
		AND	nat_cur_code = @nat_cur_code
		AND	rate = @rate
                AND     rate_oper = @rate_oper
                AND     rate_type_home = @rate_type_home
                AND     rate_type_oper = @rate_type_oper
		AND	trx_type = @trx_type
		AND	offset_flag = 0

		IF ( @update_seq_id IS NOT NULL )
		BEGIN
			SELECT	@insert_required = 0
			
			IF ( @debug > 3 )
			BEGIN
				SELECT	'*** gltrxcrd_sp - Updating account summary for '+
					@journal_ctrl_num+' sequence_id = '+
					convert(char(10), @update_seq_id )
			END
			





			UPDATE  #gltrxdet
			SET     balance = balance + @balance,
				nat_balance = nat_balance + @nat_balance,
                                balance_oper = balance_oper + @balance_oper,
				document_1 = ' ',
				document_2 = ' ',
				description = ' '
			WHERE   journal_ctrl_num = @journal_ctrl_num
			AND	sequence_id = @update_seq_id

		END

	END

	


IF (DATALENGTH(ISNULL(RTRIM(LTRIM(@ib_org_id)),''))=0) 
BEGIN
						SELECT @ib_org_id = organization_id
						   FROM Organization
						WHERE outline_num = '1'		
END


	IF ( @insert_required = 1 )
	BEGIN

		

		





		SELECT  @sequence_id = next_seq_id
		FROM    #gltrx
		WHERE   journal_ctrl_num = @journal_ctrl_num
		
		UPDATE	#gltrx
		SET	next_seq_id = next_seq_id + 1
		WHERE	journal_ctrl_num = @journal_ctrl_num

		IF ( @debug > 3 )
		BEGIN
			select ' Next Sequence_id for detail line in #gltrxdet'
			select convert(char(15), @sequence_id)
		END
		


		INSERT  #gltrxdet (
			journal_ctrl_num,      
			sequence_id,    
			rec_company_code,
			company_id ,            
			account_code,   
			description,
			document_1,             
			document_2,     
			reference_code,
			balance,                
                        nat_balance,
                        balance_oper,    
			nat_cur_code,
			rate,                   
                        rate_oper,
                        rate_type_home,
                        rate_type_oper,
			posted_flag,    
			date_posted,
			trx_type,               
			offset_flag,    
			seg1_code,
			seg2_code,              
			seg3_code,      
			seg4_code,
			seq_ref_id,
			trx_state,
			mark_flag,
			org_id )

		VALUES (@journal_ctrl_num,      
			@sequence_id,          
			@rec_company_code,
			@company_id ,           
			@account_code,  
			@description,
			@document_1,            
			@document_2,    
			@reference_code,
			@balance,               
			@nat_balance,   
                        @balance_oper,    
			@nat_cur_code,
			@rate,                  
                        @rate_oper,
                        @rate_type_home,
                        @rate_type_oper,
			0,              
			0,
			@trx_type,              
			0,   
			@seg1_code,
			ISNULL( @seg2_code, ' ' ),
			ISNULL( @seg3_code, ' ' ),
			ISNULL( @seg4_code, ' ' ),
			@seq_ref_id,
			0,
			0,
			@ib_org_id  )

		IF ( @@error != 0 )
			RETURN	1039

		IF ( @debug > 3 )
		BEGIN
			SELECT	'*** gltrxcrd_sp - Inserting transaction '+
				@journal_ctrl_num+' sequence_id = '+
				convert(char(10), @sequence_id )
		END
	END
		
	IF ( @interface_mode = 1 and @insert_required = 1 )
	BEGIN
		EXEC	@result = gltrxval_sp	@home_company,
						@journal_ctrl_num, 
						@sequence_id,
						@debug
		RETURN	@result
	END

	IF ( @debug > 0 )
		SELECT	'*** gltrxcrd_sp - Leaving gltrxcrd_sp'
		
	RETURN	0

END
GO
GRANT EXECUTE ON  [dbo].[gltrxcrd_sp] TO [public]
GO
