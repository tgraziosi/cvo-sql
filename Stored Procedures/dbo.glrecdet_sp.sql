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











































CREATE PROCEDURE [dbo].[glrecdet_sp] 
	@d_jour_num 		varchar(32),	
	@d_date_applied 	int,	
	@d_prd_num 		smallint, 
	@d_track_flag 		smallint,	
	@d_perc_flag 		smallint,	
	@d_zero_flag 		smallint,
	@d_track_amt 		float,	
	@d_base_amt 		float,	
	@d_next_jour 		varchar(32),
	@company_id		smallint,
	@recur_description	varchar(40),
	@nat_cur_code		varchar(8),
	@rate			float,
        @rate_oper              float,
        @rate_type_home         varchar(8),
        @rate_type_oper         varchar(8),
	@d_proc_key 		smallint,	
	@d_user_id 		smallint, 	
	@d_orig_flag 		smallint

AS




DECLARE	
	@last_sqid		smallint,	
	@sqid			smallint,		
	@gl_sqid 		smallint,	
	@acct_code 		varchar(32),	
	@doc_num 		varchar(32),   
	@amount 		float,
	@home_amount 		float,	 
	@tot_amt 		float,		
	@not_enough_fund	smallint,    
	@origin_track 		float,
	@gl_module 		int,	
	@rc			int,
	@err_mess 		varchar(80),
	@rec_company_code 	varchar(8),
	@result			smallint,
	@offset_flag		smallint,
	@reference_code		varchar(32),
	@seg1_code		varchar(32),
	@seg2_code		varchar(32), 	
	@seg3_code		varchar(32),  
	@seg4_code		varchar(32),
	@client_id		varchar(20),
	@E_INVALID_REC_TRX	int,
	@sub_comp_id		smallint,
        @seq_ref_id             int,
        @oper_amount             float,
	@org_id			varchar(30),
	@str_msg		VARCHAR(255),
	@str_msg2		VARCHAR(255)

SELECT	@not_enough_fund = 0, 
	@gl_module = 6000,
	@client_id = "POSTTRX"

SELECT	@E_INVALID_REC_TRX = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_INVALID_REC_TRX"




IF ( @d_track_flag = 1 )
BEGIN
	SELECT	@tot_amt = 0.0

	IF ( @d_prd_num = 1 )
	BEGIN
		SELECT	@tot_amt = SUM( amount_period_1 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_1 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 2 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_2 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_2 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 3 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_3 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_3 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 4 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_4 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_4 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 5 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_5 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_5 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 6 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_6 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_6 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 7 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_7 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_7 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 8 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_8 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_8 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 9 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_9 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_9 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 10 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_10 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_10 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 11 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_11 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_11 >= 0		
		  AND	offset_flag = 0
	END
	ELSE IF ( @d_prd_num = 12 )
	BEGIN
	       	SELECT  @tot_amt = SUM( amount_period_12 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_12 >= 0		
		  AND	offset_flag = 0
	END
	ELSE   
	BEGIN
		SELECT  @tot_amt = SUM( amount_period_13 )
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
		  AND	amount_period_13 >= 0		
		  AND	offset_flag = 0
	END
	
	SELECT  @rc = @@ROWCOUNT

	



	IF ( @rc = 0 )
	BEGIN

		EXEC appgetstring_sp "STR_RECURRING_TRANSACTION", @str_msg OUT
		EXEC appgetstring_sp "STR_IS_INVALID", @str_msg2 OUT

		SELECT	@err_mess = @str_msg + 
					RTRIM(@d_jour_num) +
					+ @str_msg2

		EXEC status_sp "GLRECDET", @d_proc_key, @d_user_id, 
			@err_mess, 0, @d_orig_flag, 1

		EXEC @result =	glputerr_sp 	@client_id, 
						@d_user_id,
						@E_INVALID_REC_TRX,
						"GLRECDET.SP",
						NULL,  		
						@d_jour_num,	
						NULL,		
						NULL,		
						NULL		
		IF ( @result > 2 )
			RETURN @E_INVALID_REC_TRX
	END

	IF ( @d_perc_flag = 1 )
		SELECT	@tot_amt = @d_base_amt * @tot_amt / 100

	




	IF ( @tot_amt > @d_track_amt )
		SELECT	@not_enough_fund = 1
	ELSE
		SELECT	@not_enough_fund = 0

	SELECT	@origin_track = @d_track_amt
END




SELECT	@sqid = -1

WHILE ( 1 = 1 )
BEGIN
	SELECT	@last_sqid = @sqid
	SET	ROWCOUNT  1

	


        SELECT  @sqid = NULL

       	SELECT	@sqid 		= sequence_id,
       		@acct_code 	= account_code, 
		@doc_num 	= document_1,
		@rec_company_code = rec_company_code,
		@offset_flag 	= offset_flag,
		@reference_code	= reference_code,
		@seg1_code	= seg1_code,
		@seg2_code 	= seg2_code,
		@seg3_code	= seg3_code,
		@seg4_code	= seg4_code,
		@seq_ref_id	= seq_ref_id,
		@org_id		= org_id
       	FROM    glrecdet
        WHERE   journal_ctrl_num = @d_jour_num
       	  AND   sequence_id > @last_sqid
	  AND	offset_flag = 0
	ORDER BY sequence_id

	


	IF ( @@ROWCOUNT = 0 ) 
	BEGIN
		SET ROWCOUNT  0
		BREAK
	END

	SET	ROWCOUNT  0

	SELECT	@amount = NULL

	IF ( @d_prd_num = 1 )
	       	SELECT  @amount = amount_period_1
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 2 )
	       	SELECT  @amount = amount_period_2
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 3 )
	       	SELECT  @amount = amount_period_3
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 4 )
	       	SELECT  @amount = amount_period_4
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 5 )
	       	SELECT  @amount = amount_period_5
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 6 )
	       	SELECT  @amount = amount_period_6
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 7 )
	       	SELECT  @amount = amount_period_7
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 8 )
	       	SELECT  @amount = amount_period_8
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 9 )
	       	SELECT  @amount = amount_period_9
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 10 )
	       	SELECT  @amount = amount_period_10
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 11 )
	       	SELECT  @amount = amount_period_11
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE IF ( @d_prd_num = 12 )
	       	SELECT  @amount = amount_period_12
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid
	ELSE    
	       	SELECT  @amount = amount_period_13
	       	FROM    glrecdet
        	WHERE   journal_ctrl_num = @d_jour_num
	       	  AND   sequence_id  = @sqid

	IF ( @amount IS NULL )
	BEGIN
		SELECT	@err_mess = @str_msg + 
					RTRIM(@d_jour_num) +
					+ @str_msg2

		EXEC status_sp "GLRECDET", @d_proc_key, @d_user_id, 
			@err_mess, 0, @d_orig_flag, 1

		EXEC @result =	glputerr_sp 	@client_id, 
						@d_user_id,
						@E_INVALID_REC_TRX,
						"GLRECDET.SP",
						NULL,  		
						@d_jour_num,	
						NULL,		
						NULL,		
						NULL		
		IF ( @result > 2 )
			RETURN @E_INVALID_REC_TRX
	END

	










	


	IF ( @d_perc_flag = 1 )
		SELECT	@amount = @d_base_amt * @amount / 100

	IF ( @d_track_flag = 1 )
	BEGIN
		IF ( @not_enough_fund = 1 )
			SELECT	@amount = @origin_track * @amount / @tot_amt

		IF ( @amount > 0 )
			SELECT	@d_track_amt = @d_track_amt - @amount
	END

	


	SELECT	@home_amount = @amount * ( SIGN(1 + SIGN(@rate))*(@rate) + (SIGN(ABS(SIGN(ROUND(@rate,6))))/(@rate + SIGN(1 - ABS(SIGN(ROUND(@rate,6)))))) * SIGN(SIGN(@rate) - 1) )
        


        SELECT  @oper_amount = @amount * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )

	


	SELECT	@sub_comp_id = company_id
	FROM	glcomp_vw
	WHERE	company_code = @rec_company_code

	


	EXEC @result = glacsum_sp 
	     @gl_module,         
	     @d_next_jour,       
	     @rec_company_code,  
	     @sub_comp_id,       
	     @acct_code,         
	     @recur_description, 
	     @doc_num,	         
	     @d_jour_num,        
	     @reference_code,    
	     @home_amount,       
	     @amount,	         
	     @nat_cur_code,      
	     @rate,	         
	     111, 	         
	     @offset_flag,       
             @oper_amount,          
             @rate_oper,            
             @rate_type_home,       
             @rate_type_oper,       
	     @seg1_code,
	     @seg2_code, 	
	     @seg3_code,
	     @seg4_code,
	     @seq_ref_id,
	     NULL,
	     @org_id		 
             
	    
             

	     



	     IF	( @result != 0 )
	     	RETURN @result

END	

IF ( @d_track_flag = 1 )
BEGIN
	IF ( @not_enough_fund = 1 )
		UPDATE	glrecur
		SET	tracked_balance_amount = 0
		WHERE	journal_ctrl_num = @d_jour_num
	ELSE
		UPDATE	glrecur
		SET	tracked_balance_amount = @d_track_amt
		WHERE	journal_ctrl_num = @d_jour_num
END

RETURN 0






/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glrecdet_sp] TO [public]
GO
