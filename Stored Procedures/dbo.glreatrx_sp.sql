SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                





























































CREATE	PROCEDURE [dbo].[glreatrx_sp] 	@posted_flag 	int,
				@jour_num	varchar(16),
				@description	varchar(40),
				@sys_date 	int,
				@cur_date	int,
				@company_code 	varchar(8),
				@nat_cur_code	varchar(8),
                                @oper_cur_code  varchar(8),
				@proc_key 	smallint,
				@user_id 	smallint,
				@user_name	varchar(30),
				@orig_flag 	smallint,
				@ret_error      smallint  OUTPUT,
                                @debug          smallint     = 0

AS
DECLARE
	@amount 	 	float,
	@balance 	 	float,
	@balance_date 		int,
	@base_acct 	 	varchar(32),
	@base_amt	 	float,
	@base_type 	 	smallint,
	@bud_code 	 	varchar(16),
	@bud_flag 	 	smallint,
	@client_id		varchar(20),
	@company_id 	 	smallint,
	@detail_acct 	 	varchar(32),
	@divider 	 	float,
	@doc_num 	 	varchar(32),
	@E_CANT_INSERT_GLTRX	int,
	@E_CANT_INS_GLTRXDET	int,
	@E_INVALID_BUDGET_CD	int,
	@E_INVALID_NONFIN_CD	int,
	@E_INVALID_COMPCODE	int,
	@E_INVALID_NATCODE	int,
	@E_DB_ERROR		int,
	@E_NO_BALANCE_FOUND	int,
	@err_msg 	 	varchar(80),
	@gl_module 	 	int,
	@hold_flag 	 	smallint,
	@int_buff 	 	int,
	@intercompany_flag	smallint,
	@last_applied 		int,
	@last_date 	 	int,
	@last_jrn 	 	varchar(16),
	@last_sqid		int,
	@len 		 	smallint,
	@next_batch_code 	varchar(16),
	@next_code 	 	varchar(32),
	@no_fin_code 	 	varchar(16),
	@non_fin_flag 		smallint,
	@offset_flag	 	smallint,
	@perc_done	 	float,
	@perc_flag 	 	smallint,
	@period 	 	smallint,
	@prd_begin 	 	int,
	@real_type 	 	smallint,
	@rec_company_code	varchar(8),
    	@rec_company_id		smallint,
	@reference_code		varchar(32),
	@result			int,
	@save_date	 	int,
	@seg1_code 	 	varchar(32),
	@seg2_code  	 	varchar(32),
	@seg3_code	 	varchar(32),
	@seg4_code	 	varchar(32),
	@sqid 		 	smallint,
	@start_col 	 	smallint,
	@tmpbal 	 	float,
	@tot_cr 	 	float,
	@tran_started		tinyint,
        @seq_ref_id             int,

        @amount_oper            float,
        @balance_oper           float,
        @tmpbal_oper            float,
        @tot_cr_oper            float,
        @base_amt_oper          float,
        @divider_oper           float,
        @rate_type_oper         varchar(8),
        @rate_type_home         varchar(8),
        @rate_oper              float,
        @rate_oper_trans        float,
        @perc_calc              smallint,
        @min_sequence_id        int,
	@precision_home		smallint,
	@precision_oper		smallint,
	@tmp_bal		float,
	@tmp_bal_oper		float,
	@org_id			varchar(30),
	@base_org_id		varchar(30),
	@interbranch_flag	int

IF @debug >= 1
	SELECT "________________________ Entering GLREATRX.SP ________________________"	 " "

SELECT @rate_type_home = rate_type_home,
       @rate_type_oper = rate_type_oper
FROM glco




SELECT 	@precision_home = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @nat_cur_code	

SELECT 	@precision_oper = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @oper_cur_code	

IF @debug >= 3
	SELECT 	@jour_num	 	"--- Journal ctrl num",
		@posted_flag		"Post flag",
		@sys_date		"Sys date",
		@cur_date		"Cur date"




SELECT	@E_INVALID_NATCODE = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_NATCODE"

SELECT	@E_INVALID_BUDGET_CD = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_BUDGET_CD"

SELECT	@E_INVALID_NONFIN_CD = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_NONFIN_CD"

SELECT	@E_CANT_INSERT_GLTRX = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_CANT_INSERT_GLTRX"

SELECT	@E_CANT_INS_GLTRXDET = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_CANT_INS_GLTRXDET"

SELECT	@E_INVALID_COMPCODE = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_COMPCODE"

SELECT	@E_NO_BALANCE_FOUND = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_NO_BALANCE_FOUND"

SELECT	@E_DB_ERROR = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_DB_ERROR"



SELECT	@perc_flag = 1,
	@bud_flag = 2,
	@real_type = 3,
	@non_fin_flag = 3,
	@gl_module = 6000,
	@tran_started = 0,
	@client_id = "POSTTRX",
        @ret_error = 0,
        @rate_oper     = NULL,
        @perc_calc = 1





IF ( @@trancount = 0 )
BEGIN
	BEGIN TRAN
	SELECT	@tran_started = 1
	IF @debug >= 2
		SELECT "--  Transaction started" " "
END

SELECT	@bud_code	= budget_code,
	@no_fin_code	= nonfin_budget_code,
	@base_acct	= account_code,
	@hold_flag	= hold_flag,
	@base_type	= based_type,
	@intercompany_flag = intercompany_flag,
	@last_applied	= date_last_applied,
	@base_org_id	= org_id
FROM	glreall
WHERE	journal_ctrl_num = @jour_num




SELECT	@company_id = company_id
FROM	glcomp_vw
WHERE	company_code = @company_code





IF @hold_flag = 1 OR @cur_date <= @last_applied
BEGIN
	IF ( @tran_started = 1 )
	BEGIN
		ROLLBACK TRAN
		SELECT	@tran_started = 0
	END

	UPDATE	glreall
	SET	posted_flag = 0
	WHERE	journal_ctrl_num = @jour_num

	IF @debug >= 3
		SELECT "--- Hold flag set, or transaction already applied" " "

	RETURN 0
END




SELECT   @base_amt = 0,@base_amt_oper = 0

EXEC @result = glgetbal_sp 	@base_acct,
	      			@cur_date,
	      			1,
	      			@tmpbal		OUTPUT,
                                @base_amt       OUTPUT,
                                @tmpbal_oper    OUTPUT,
                                @base_amt_oper  OUTPUT







IF (( @base_amt IS NULL  OR  @base_amt = 0.0
       OR 
      @base_amt_oper IS NULL  OR  @base_amt_oper = 0.0 )
   AND  @base_type > 0 )

BEGIN
	


	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRAN
		SELECT	@tran_started = 0
	END

	UPDATE	glreall
	SET	posted_flag = 0,
		date_last_applied = @cur_date
	WHERE	journal_ctrl_num = @jour_num

	



	EXEC @result =	glputerr_sp 	@client_id,
					@user_id, 	
					@E_NO_BALANCE_FOUND,
					"glreatrx.SP",
					NULL,  		
					@jour_num, 	
					NULL,		
					NULL,		
					NULL		
	IF @debug >= 3
		SELECT "--- Base amount is zero - skipping this transaction" " "

	



	SELECT @ret_error=1

	RETURN 0
END




ELSE
BEGIN
   IF ((( @base_amt IS NULL ) OR ( @base_amt = 0.0 )) AND ( @base_type = 0 ))
     SELECT  @base_amt = 1.0, @perc_calc = 0
   IF ((( @base_amt_oper IS NULL ) OR ( @base_amt_oper = 0.0 )) AND ( @base_type = 0 ))
   BEGIN
     EXEC @result = CVO_Control..mccurate_sp
                      @cur_date,                
                      @nat_cur_code,            
                      @oper_cur_code,          
                      @rate_type_oper  ,
                      @rate_oper OUTPUT,            
                      0                         
        
     SELECT @base_amt_oper = @base_amt * @rate_oper
     IF ((@result != 0) OR (@base_amt_oper = 0.0) OR (@rate_oper = 0.0))
     BEGIN
       IF ( @tran_started = 1 )
       BEGIN
         ROLLBACK TRAN
         SELECT   @tran_started = 0
       END

       RETURN @E_DB_ERROR
     END
   END
END

SELECT   @divider = NULL,
         @divider_oper = NULL

IF ( @base_type = @perc_flag )
BEGIN
   SELECT   @divider = 100,
            @divider_oper = 100
END
   ELSE IF ( @base_type = @bud_flag )
   BEGIN
      IF @debug >= 3
         SELECT "--- Getting budget amount" " "

      SELECT   @divider = net_change,
               @divider_oper = net_change_oper
      FROM  glbuddet
      WHERE period_end_date = @cur_date
         AND   budget_code = @bud_code
         AND   account_code = @base_acct

      



      IF (( @divider IS NULL ) OR ( @divider = 0.0 )
         OR               
         ( @divider_oper IS NULL ) OR ( @divider_oper = 0.0 )
         )
      BEGIN
         IF ( @tran_started = 1 )
         BEGIN
            ROLLBACK TRAN
            SELECT @tran_started = 0
         END

         RETURN @E_INVALID_BUDGET_CD
      END

   END
   ELSE
   IF ( @base_type = @non_fin_flag )
   BEGIN
         IF @debug >= 3
            SELECT "--- Getting non-financial amount" " "

         SELECT   @divider = quantity
         FROM  glnofind
         WHERE period_end_date = @cur_date
            AND   nonfin_budget_code = @no_fin_code
            AND   account_code = @base_acct

         SELECT @divider_oper = @divider
         



         IF (( @divider IS NULL ) OR ( @divider = 0.0 ))
         BEGIN
            IF ( @tran_started = 1 )
            BEGIN
               ROLLBACK TRAN
               SELECT   @tran_started = 0
            END

            RETURN @E_INVALID_NONFIN_CD
         END
   END
   ELSE  
     SELECT   @divider = @base_amt,
              @divider_oper = @base_amt_oper





EXEC  @result = glnxttrx_sp   @next_code  OUTPUT

IF ( @result != 0 )
BEGIN

	IF ( @tran_started = 1 )
	BEGIN
		ROLLBACK TRAN
		SELECT	@tran_started = 0
	END

	IF @debug >= 3
		SELECT "--- Error generating next journal number" " "

	RETURN @result
END

SELECT   @save_date = @cur_date, @tot_cr = 0.0, @tot_cr_oper = 0.0




EXEC @result = glnxtbat_sp	@gl_module,
	      			" ",
	      			6020,
                       		@user_name,
	      			@save_date,
	      			@company_code,
                       		@next_batch_code OUTPUT,
				@base_org_id	

IF ( @result != 0 )
BEGIN
	IF ( @tran_started = 1 )
	BEGIN
		ROLLBACK TRAN
		SELECT	@tran_started = 0
	END

	IF @debug >= 3
		SELECT "--- Error creating new batch code" " "

	RETURN @result
END

IF @debug >= 2
	SELECT "-- Creating new transaction header" " "





INSERT	gltrx
	(journal_type,		journal_ctrl_num,
	journal_description,	date_entered,
	date_applied,		recurring_flag,
	repeating_flag,		reversing_flag,
	hold_flag,		posted_flag,
	date_posted,		source_batch_code,
	batch_code,     	type_flag,
	intercompany_flag,	company_code,
	app_id,		  	home_cur_code,
	document_1,		trx_type,
	user_id,		source_company_code,
   	process_group_num,	oper_cur_code,
	org_id,			interbranch_flag
   )
SELECT	journal_type,		@next_code,
	journal_description,	@sys_date,
	@save_date,		0,
	0,			0,
	0, 			0,
	0,			" ",
	@next_batch_code, 	@real_type ,
        intercompany_flag,	@company_code,
	@gl_module,		@nat_cur_code,
	@jour_num,		111,
	@user_id,		" ",
   	" ",			@oper_cur_code,
	org_id,			interbranch_flag
FROM	glreall
WHERE	journal_ctrl_num = @jour_num

IF ( @@rowcount != 1 )
BEGIN
	IF ( @tran_started = 1 )
	BEGIN
		ROLLBACK TRAN
		SELECT	@tran_started = 0
	END

	RETURN @E_CANT_INSERT_GLTRX
END

SELECT @interbranch_flag =0
SELECT @interbranch_flag = interbranch_flag FROM	glreall
WHERE	journal_ctrl_num = @jour_num
	IF (@interbranch_flag=1)
		INSERT ibifc (	id,		date_entered,		date_applied,	controlling_org_id,	detail_org_id,
				amount,		currency_code,		tax_code,	state_flag,		trx_type,		
				link1,		link2,			username)
		SELECT		newid(), 	dateadd(day, @sys_date  - 693596, '01/01/1900'),		dateadd(day,@save_date-693596, '01/01/1900'), 	
											'',			'',
				0,		@nat_cur_code,		'',		0,			111 , 			
				@next_code, '' ,	SYSTEM_USER




IF @debug >= 2
	SELECT "-- Processing detail lines" " "

SELECT	@tmp_bal = 0.0,
	@tmp_bal_oper = 0.0



SELECT	@sqid = -1

WHILE ( @sqid != 0 )
BEGIN
	SELECT	@last_sqid = @sqid
	SELECT	@sqid = NULL
	


        SELECT  @min_sequence_id = MIN(sequence_id)                              
        FROM    glreadet                                                                   
        WHERE   journal_ctrl_num = @jour_num                                           
        AND     sequence_id > @last_sqid                                           

        SELECT  @sqid             = sequence_id,
		@detail_acct 	  = account_code,
		@balance 	  = balance,
		@doc_num 	  = document_1,
		@rec_company_code = rec_company_code,
		@reference_code   = reference_code,
		@offset_flag 	  = offset_flag,
		@seg1_code	  = seg1_code,
		@seg2_code	  = seg2_code,
		@seg3_code	  = seg3_code,
		@seg4_code	  = seg4_code,
		@seq_ref_id	  = seq_ref_id,
		@org_id		  = org_id
	FROM	glreadet
	WHERE	journal_ctrl_num = @jour_num
	AND	sequence_id > @last_sqid
        AND     sequence_id = @min_sequence_id
        
        


	IF ( @@error != 0 )
		goto rollback_trx

	


	IF ( @sqid IS NULL )
	BEGIN
		BREAK
	END

	IF @debug >= 3
		SELECT "--- Processing line " + CONVERT(varchar(6), @sqid) " "

	


	SELECT	@rec_company_id = NULL

	SELECT 	@rec_company_id = company_id
	FROM	glcomp_vw
	WHERE	company_code = @rec_company_code
	


	IF ( @rec_company_id IS NULL )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END

		RETURN @E_INVALID_COMPCODE
	END

	IF ( @base_type = @bud_flag )
	BEGIN
		IF @debug >= 3
			SELECT "--- Processing budget transaction" " "
                SELECT  @balance = NULL,
                        @balance_oper = NULL

                SELECT  @balance = net_change,
                        @balance_oper = net_change_oper
		FROM	glbuddet
		WHERE	period_end_date = @cur_date
			AND	budget_code = @bud_code
			AND	account_code = @detail_acct

                IF ( @balance IS NULL OR @balance_oper IS NULL)
		BEGIN
			IF ( @tran_started = 1 )
			BEGIN
				ROLLBACK TRAN
				SELECT	@tran_started = 0
			END

			RETURN @E_INVALID_BUDGET_CD
		END
	END
        ELSE
        IF ( @base_type = @non_fin_flag )
	BEGIN
		IF @debug >= 3
			SELECT "--- Processing budget transaction" " "
                SELECT  @balance = NULL,
                        @balance_oper = NULL

		SELECT	@balance = quantity
		FROM	glnofind
		WHERE	period_end_date = @cur_date
			AND	nonfin_budget_code = @no_fin_code
			AND	account_code = @detail_acct

                SELECT  @balance_oper = @balance

		IF ( @balance IS NULL )
		BEGIN
			IF ( @tran_started = 1 )
			BEGIN
				ROLLBACK TRAN
				SELECT	@tran_started = 0
			END

			RETURN @E_INVALID_NONFIN_CD
		END
	END
        ELSE
        IF ( @base_type = @perc_flag ) SELECT @balance_oper = @balance

	SELECT	@amount = @base_amt * @balance / @divider

        IF (@base_type = 0)
        BEGIN
          IF (@perc_calc != 0)
            SELECT  @amount_oper = @base_amt_oper * @balance/@base_amt
          ELSE
            SELECT  @amount_oper = @amount * @rate_oper
        END
        ELSE
          SELECT  @amount_oper = @base_amt_oper * @balance_oper / @divider_oper
	


	IF @debug >= 3
		SELECT "---  Rounding amount" " "



	SELECT @amount = (SIGN(@amount) * ROUND(ABS(@amount) + 0.0000001, @precision_home))
	SELECT @amount_oper = (SIGN(@amount_oper) * ROUND(ABS(@amount_oper) + 0.0000001, @precision_oper))
	SELECT @base_amt = (SIGN(@base_amt) * ROUND(ABS(@base_amt) + 0.0000001, @precision_home))
	SELECT @base_amt_oper = (SIGN(@base_amt_oper) * ROUND(ABS(@base_amt_oper) + 0.0000001, @precision_oper))
	SELECT @tmp_bal = (SIGN(@tmp_bal) * ROUND(ABS(@tmp_bal) + 0.0000001, @precision_home))
	SELECT @tmp_bal_oper = (SIGN(@tmp_bal_oper) * ROUND(ABS(@tmp_bal_oper) + 0.0000001, @precision_oper))


	IF @debug >= 3
		SELECT "---  Entering detail line with GLACSUM" " "

	

	IF (( @base_type = @perc_flag ) AND ( @intercompany_flag = 0 ))
	BEGIN
		
		IF ( ABS( @tmp_bal + @amount ) > ABS(@base_amt) )
			SELECT	@amount = @base_amt -  @tmp_bal
		IF ( ABS( @tmp_bal_oper + @amount_oper ) > ABS(@base_amt_oper) )
			SELECT	@amount_oper = @base_amt_oper -  @tmp_bal_oper

		SELECT 	@tmp_bal = @tmp_bal + @amount,
			@tmp_bal_oper = @tmp_bal_oper + @amount_oper
	END
	 
	IF @amount <> 0 
		SELECT @rate_oper_trans = @amount_oper/@amount
	IF @amount = 0 	
		SELECT @rate_oper_trans = 0

	EXEC @result = glacsum_sp
		@gl_module,       	
		@next_code,       	
		@rec_company_code,	
		@rec_company_id,  	
		@detail_acct,     	
		@description,     	
		@doc_num,	  	
		@jour_num,	  	
		@reference_code,  	
		@amount,	  	
                @amount,                
		@nat_cur_code,    	
                1.0,                    
		111,			
		@offset_flag,		
                @amount_oper,           
                @rate_oper_trans,       
                @rate_type_home,        
                @rate_type_oper,        
		@seg1_code,
		@seg2_code,
		@seg3_code,
		@seg4_code,
                @seq_ref_id,
                0,
		@org_id


	IF ( @@error != 0 )
		SELECT	@result = @E_DB_ERROR

	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT	@tran_started = 0
		END

		RETURN @result
	END

   SELECT   @tot_cr = @tot_cr - @amount,
            @tot_cr_oper = @tot_cr_oper - @amount_oper
END





IF @debug >= 2
	SELECT "--  Entering base amount detail line with GLACSUM" " "

IF @tot_cr != 0.0
BEGIN
  SELECT @rate_oper_trans = @tot_cr_oper/@tot_cr

  EXEC @result = glacsum_sp
	@gl_module,		
	@next_code,		
	@company_code,		
	@company_id,		
	@base_acct,		
	@description,		
	@doc_num,		
	@jour_num,		
	'',			 
	@tot_cr,		
        @tot_cr,                
	@nat_cur_code,		
        1.0,                    
	111,			
	0,			
        @tot_cr_oper,           
        @rate_oper_trans,       
        @rate_type_home,        
        @rate_type_oper,        
	" ",
	" ",
	" ",
        " ",
        0,
        0,
	@base_org_id

  IF ( @@error != 0 )
	SELECT	@result = @E_DB_ERROR

  IF ( @result != 0 )
  BEGIN
	IF ( @tran_started = 1 )
	BEGIN
		ROLLBACK TRAN
		SELECT	@tran_started = 0
	END

	RETURN @result
  END
END






IF @debug >= 2
	SELECT "-- Updating BATCHCTL" " "

UPDATE batchctl
SET    actual_number =
               (SELECT count(*)
                FROM   gltrx
                WHERE  batch_code = @next_batch_code),
        actual_total = 0.0
WHERE  batch_ctrl_num = @next_batch_code

IF ( @@error != 0 )
	goto rollback_trx

IF @debug >= 2
	SELECT "-- Updating GLREAL" " "

UPDATE	glreall
SET	posted_flag = 0,
	date_last_applied = @save_date,
	date_posted = @sys_date
WHERE	journal_ctrl_num = @jour_num

IF ( @@error != 0 )
	goto rollback_trx

UPDATE	glreadet
SET	date_posted = @sys_date,
	posted_flag = 0
WHERE	journal_ctrl_num = @jour_num

IF ( @@error != 0 )
	goto rollback_trx





IF ( @tran_started = 1 )
BEGIN
	COMMIT TRAN
	SELECT	@tran_started = 0
	IF @debug >= 2
		SELECT "-- Committing transaction" " "
END
IF @debug >= 1
	SELECT "________________________ Leaving GLREATRX.SP ________________________" " "

RETURN 0





rollback_trx:

IF ( @tran_started = 1 )
	ROLLBACK TRAN

UPDATE	glreall
SET	posted_flag = 0
WHERE	journal_ctrl_num = @jour_num

RETURN	@E_DB_ERROR
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glreatrx_sp] TO [public]
GO
