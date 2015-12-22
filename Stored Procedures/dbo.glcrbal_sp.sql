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













































CREATE PROC [dbo].[glcrbal_sp]
	@jrn_code		varchar(16),
	@desc			varchar(30),
	@jrn_type		varchar(8),
	@date			int,
	@apply_date		int,
	@from_acct		varchar(32),
	@to_acct		varchar(32),
	@from_org_id		varchar(30),
	@to_org_id		varchar(30),
	@rec_userid 		smallint

AS

DECLARE 
	@numrec 	int, 		@acct_code 	varchar(32), 
	@tot_trx 	float, 		@perc_done 	smallint, 	
	@total_done 	float,		@company_code 	varchar(8),
	@company_id 	smallint,	@home_currency varchar(8),
	@seg1_code	varchar(32),	@seg2_code	varchar(32),
    @seg3_code      varchar(32),    @seg4_code      varchar(32),
    @oper_currency  varchar(8),     @acct_cur_code  varchar(8),
    @rate_type_home varchar(8),     @rate_type_oper varchar(8),
    @acct_rate_type_home    varchar(8),     
    @acct_rate_type_oper     varchar(8),
    @rate           float,          @rate_oper      float,
    @result         int,		@msg 		varchar(80), 	
	@org_id 	varchar(30), @str_msg		varchar(255)



SELECT 	@company_code = company_code,
	@company_id = company_id,
        @home_currency = home_currency,
        @oper_currency = oper_currency,
        @rate_type_home = rate_type_home,
        @rate_type_oper = rate_type_oper
FROM 	glco
	



SELECT @org_id = @from_org_id

WHILE(@org_id <= @to_org_id)
BEGIN
	


	INSERT gltrx (
		timestamp,		journal_type,	journal_ctrl_num,
		journal_description,	date_entered,	date_applied,
		recurring_flag,		repeating_flag,	reversing_flag,
		hold_flag,		posted_flag,	date_posted,
		source_batch_code,	batch_code,	type_flag,
		intercompany_flag,	company_code,	app_id,
		home_cur_code,		document_1,	trx_type,
		user_id,		source_company_code,
	        process_group_num,      oper_cur_code,	org_id,
		interbranch_flag )
	VALUES (
		NULL, 			@jrn_type, 	@jrn_code, 
		@desc, 			@date, 		@apply_date, 
		0, 			0, 		0, 
		1, 			0, 		0, 
		"", 			"", 		1, 
		0,			@company_code,	6000,
		@home_currency,		"",		101,
	        @rec_userid,            '',             ' ',
	        @oper_currency,		@org_id,	0 )

	
	


	SELECT	@tot_trx = NULL, @perc_done = 0, @total_done = 0
	
	SELECT	@tot_trx = COUNT(account_code)
	FROM	glchart
	WHERE	account_code >= @from_acct
	AND	account_code <= @to_acct	
	AND	account_code  IN (SELECT account_code FROM sm_accounts_access)
	AND	@org_id = organization_id
	
	


	IF (( @tot_trx IS NULL ) OR ( @tot_trx !> 0.0 ))
	BEGIN
		SELECT @msg = "No accounts to continue!"
		SELECT @msg
		IF(@org_id = @to_org_id)
			RETURN
		ELSE
		BEGIN
			SELECT @org_id = min(organization_id)
			FROM Organization 
			WHERE organization_id > @org_id
				AND region_flag = 0

			EXEC    @result = gltrxnew_sp   @company_code, @jrn_code OUTPUT

			CONTINUE
		END

	END
	
	


	SELECT @acct_code = ( SELECT min(account_code)
				FROM glchart 
				WHERE account_code >= @from_acct
				AND @org_id = organization_id )
	SELECT @numrec = 1
	
	


	WHILE @acct_code <= @to_acct
	BEGIN
	        SELECT  @acct_cur_code = NULL,
	                @acct_rate_type_home  = NULL,
	                @acct_rate_type_oper  = NULL,
	                @rate = NULL,
	                @rate_oper = NULL
	        SELECT  @seg1_code = seg1_code,
			@seg2_code = seg2_code,
			@seg3_code = seg3_code,
	                @seg4_code = seg4_code,
	                @acct_cur_code = currency_code,
	                @acct_rate_type_home = rate_type_home,
	                @acct_rate_type_oper = rate_type_oper
		FROM	glchart
		WHERE	account_code = @acct_code
	
	        IF ( ( @acct_cur_code IS NULL ) 
	        OR ( @acct_cur_code = CHAR(0) ) 
	        OR ( @acct_cur_code = ' ') )
	                SELECT @acct_cur_code = @home_currency
	        IF ( ( @acct_rate_type_home IS NULL )  
	        OR ( @acct_rate_type_home = CHAR(0) ) 
	        OR ( @acct_rate_type_home = ' ' ) )
	                SELECT @acct_rate_type_home = @rate_type_home
	        IF ( ( @acct_rate_type_oper IS NULL )  
	        OR ( @acct_rate_type_oper = CHAR(0) ) 
	        OR ( @acct_rate_type_oper = ' ' ) )
	                SELECT @acct_rate_type_oper = @rate_type_oper
	
	        EXEC    @result = CVO_Control..mccurate_sp   @apply_date,
	                                        @acct_cur_code,
	                                        @home_currency,
	                                        @acct_rate_type_home,
	                                        @rate OUTPUT,
	                                        0
	        IF ( @rate IS NULL )
	                SELECT @rate = 0.0
	        EXEC    @result = CVO_Control..mccurate_sp   @apply_date,
	                                        @acct_cur_code,
	                                        @oper_currency,
	                                        @acct_rate_type_oper,
	                                        @rate_oper OUTPUT,
	                                        0
	        IF ( @rate_oper IS NULL )
	                SELECT @rate_oper = 0.0

		EXEC appgetstring_sp "STR_BEGIN_BALANCE", @str_msg OUT

		INSERT gltrxdet (
			timestamp,		journal_ctrl_num,	sequence_id,		
			rec_company_code, 	company_id,		account_code,		
			description,	  	document_1,	  	document_2,		
			reference_code,	  	balance,	  	nat_balance,		
			nat_cur_code,	  	rate,		  	posted_flag,		
			date_posted,	  	trx_type,	  	offset_flag,
			seg1_code,		seg2_code,		seg3_code,
	                seg4_code,              seq_ref_id,             balance_oper,
	                rate_oper,              rate_type_home,         rate_type_oper,
			org_id )
		VALUES ( 
			NULL, 		  	@jrn_code,		@numrec, 
			@company_code,	  	@company_id,		@acct_code, 		
			@str_msg,	"",		  	"",			
			"",		  	0, 			0, 			
	                @acct_cur_code,         @rate,                  0, 
			0, 			101, 			0,
			@seg1_code,		@seg2_code,		@seg3_code,
	                @seg4_code,             0,                      0.0,
	                @rate_oper,             @acct_rate_type_home,   @acct_rate_type_oper,
			@org_id )
	
		


		SELECT @acct_code = ( SELECT min(account_code)
						FROM glchart 
						WHERE account_code > @acct_code
						AND @org_id = organization_id )
		SELECT @numrec = @numrec + 1
	
		


		SELECT	@total_done = @total_done + 1, 
			@perc_done = @total_done / @tot_trx * 100
	
	END        
	


	SELECT @org_id = min(organization_id)
		FROM Organization 
		WHERE organization_id > @org_id
		AND region_flag = 0
	


	EXEC    @result = gltrxnew_sp   @company_code, @jrn_code OUTPUT
END

SELECT @msg = "Done"
SELECT @msg 
RETURN

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcrbal_sp] TO [public]
GO
