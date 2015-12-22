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
































CREATE PROCEDURE [dbo].[mcreval_sp]
                            @x_posted_flag  int,
                            @x_post_date    int,
                            @x_proc_key     smallint,
                            @x_user_id      smallint,
                            @x_orig_flag    smallint
AS




DECLARE
  @min_company_code       varchar(8),
  @min_currency_code      varchar(32),
  @min_balance_date       int,
  @error_flag             int,
  @total_trx              int,
  @trx_done               int,
  @perc_done              int,
  @jour_type              varchar(8),
  @gl_id                  smallint,
  @next_gl_jcc            varchar(32),
  @batch_code             varchar(16),
  @account_code           varchar(32),
  @account_to_post        varchar(32),
  @balance_date           int,
  @date_revaluated        int,
  @amt_home_adjust        float,
  @amount_home            float,
  @company_code           varchar(8),
  @ret_status             int,
  @company_id             smallint,
  @rec_company_code       varchar(8),
  @mcerror_msg            varchar(50),
  @home_cur_code          varchar(8),
  @nat_currency_code      varchar(8),
  @revaled_currency_code  varchar(8),
  @account_type           smallint,
  @trx_type               smallint,
  @a1                     varchar(32),
  @a2                     varchar(32),
  @a3                     varchar(32),
  @a4                     varchar(32),
  @journal_description    varchar(30),
	@sum_oper_adjustment    float,
	@sum_home_adjustment    float,
  @amt_oper_adjust        float,
  @amount_oper            float,
  @oper_cur_code          varchar(8),
  @account_to_post_oper   varchar(32),
  @status                 int,
  @status_oper		  int,	
  @rate_type_home         varchar(8),
  @rate_type_oper         varchar(8)
  , @hdr_org_id		 	     varchar(30)
  , @org_acct_revaluated             varchar(30)
  , @org_gain_loss_acct_revaluated   varchar(30),
  @str_msg		varchar(255)


  

	




  
          
  


	EXEC appdate_sp @date_revaluated OUTPUT

  


  SELECT  @trx_type = 0140

	SELECT	@gl_id = 6000
	SELECT	@company_code = ' ', @rec_company_code = ' '

  


  SELECT  @company_id = glcomp_vw.company_id,
          @rec_company_code = glcomp_vw.company_code
  FROM    glco, glcomp_vw
  WHERE   glcomp_vw.company_id = glco.company_id


	


	SELECT	@total_trx = 0.0, 
          @trx_done = 0.0
 	SELECT	@total_trx = COUNT( account_code )
	FROM	CVO_Control..mcdist
	WHERE	posted_flag = @x_posted_flag

  


	IF (( @total_trx IS NULL ) OR ( @total_trx !> 0.0 ))
	BEGIN

		EXEC appgetstring_sp "STR_NO_TRANS_POST", @str_msg OUT

		EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
		  @str_msg, 0,
                  @x_orig_flag, 1
		RETURN
	END


  


	SELECT  @jour_type = NULL
	SELECT  @jour_type = journal_type
	FROM    glappid
	WHERE   app_id = @gl_id

	IF (( @@ROWCOUNT = 0 ) OR ( @jour_type IS NULL ) OR (@jour_type = " " ))
	BEGIN

		EXEC appgetstring_sp "STR_MCREVAL_GLAPPID_FAIL", @str_msg OUT

		EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
		 	@str_msg, 0,
                        @x_orig_flag, 1
		RETURN
	END



  




	
	IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#mcdist_org') IS NULL)  	
		DROP TABLE #mcdist_org

	CREATE TABLE #mcdist_org (
	company_code		varchar(8),
	account_code		varchar(32),
	org_id				varchar(30)
	)
	

	INSERT INTO #mcdist_org (company_code, account_code, org_id)
	SELECT company_code, account_code, "" FROM  CVO_Control..mcdist
	WHERE   posted_flag = @x_posted_flag 

	UPDATE #mcdist_org 
	SET org_id = isnull(organization_id,"")
	FROM glchart a, #mcdist_org b
	WHERE	a.account_code = b.account_code



	SELECT @revaled_currency_code = " ", @hdr_org_id = ""

	
	WHILE ( 1 = 1 )
	BEGIN

      

      SELECT  @min_company_code = min(company_code),
              @min_currency_code = min(currency_code),
              @min_balance_date = min(balance_date)
      FROM    CVO_Control..mcdist
      WHERE   posted_flag = @x_posted_flag
      SET ROWCOUNT 1
		  SELECT  @account_code = a.account_code,
			        @company_code = a.company_code,
			        @amt_home_adjust = a.amount_home_adjustment,
			        @amount_home = a.amount_home,
		 	        @balance_date = a.balance_date,
			        @home_cur_code = a.home_currency_code,
		          @nat_currency_code = a.currency_code,
		          @amt_oper_adjust = a.amount_adjustment_oper, 
		          @amount_oper = a.amount_oper,                
		          @oper_cur_code = a.oper_currency_code,       
		          @rate_type_home  = a.rate_type_home,         
		          @rate_type_oper = a.rate_type_oper,
					@org_acct_revaluated  = b.org_id         
    	FROM    CVO_Control..mcdist a, #mcdist_org b
		  WHERE	  a.posted_flag = @x_posted_flag
	  AND	  a.company_code = b.company_code
	  AND	  a.account_code = b.account_code
      AND     a.company_code = @min_company_code
      AND     a.currency_code = @min_currency_code
      AND     a.balance_date = @min_balance_date
	  ORDER BY b.org_id
                
      IF( @@ROWCOUNT = 0 )
      BEGIN
          EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
                           "Done", 100, @x_orig_flag, 0
          SET ROWCOUNT 0                  
          
          RETURN
		  END
      SET ROWCOUNT 0
       
      



      IF ((@revaled_currency_code <> @nat_currency_code) OR (@hdr_org_id <> @org_acct_revaluated) )
      BEGIN

			  SELECT @hdr_org_id = @org_acct_revaluated

		      EXEC appgetstring_sp "STR_CURRENCY_REVALUATION", @str_msg OUT

		      SELECT	@journal_description = @nat_currency_code + @str_msg
		      SELECT	@batch_code = NULL, @next_gl_jcc = NULL
		      EXEC	@ret_status = gltrxhdr_sp
                        @gl_id,                 
                        @jour_type,             
                        @next_gl_jcc OUTPUT,    
                        @journal_description,   
                        @date_revaluated,       
                        @balance_date,          
                        0,                      
                        0,                      
                        1,                      
                        ' ',                    
                        @batch_code OUTPUT,     
                        0,                      
                        0,                      
                        @company_code,          
                        @home_cur_code,          
			                   
                        ' ',                    
                        @trx_type,              
                        @x_user_id,             
                        0,                      
                        @error_flag OUTPUT     
			, @hdr_org_id			
			, 0			

	        IF ( @ret_status != 0 )
		      BEGIN

				EXEC appgetstring_sp "STR_MCREVAL_GLTRXHDR_FAIL", @str_msg OUT

			        SELECT	@mcerror_msg = @str_msg + convert(varchar(5),@ret_status)

			        EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
				                                          @mcerror_msg, 0, @x_orig_flag, 1
              
              RETURN
		      END
          
          
          
	    END

      


      EXEC @status = flcomp_sp @amt_home_adjust, 0.0
      EXEC @status_oper = flcomp_sp @amt_oper_adjust, 0.0
      IF ( (@status <> 0) OR (@status_oper <> 0) )
      	
      BEGIN

		

			
		SELECT @org_acct_revaluated = organization_id FROM glchart WHERE account_code = @account_code
	
		      EXEC @ret_status = glacsum_sp
                        @gl_id,                 
                        @next_gl_jcc,           
                        @rec_company_code,      
                        @company_id,            
                        @account_code,          
                        @journal_description,   
                        ' ',                    
                        ' ',                    
                        ' ',                    
                        @amt_home_adjust,       
                        0,                      
                        @nat_currency_code,     
                        0,                      
                        @trx_type,              
                        0,                      
                        @amt_oper_adjust,       
                        0,                      
                        @rate_type_home,        
                        @rate_type_oper,       
                        ' ',                    
                        ' ',                    
                        ' ',                    
                        ' ',                    
                        0,                      
                        @error_flag OUTPUT     
			,@org_acct_revaluated  

		      IF ( @ret_status != 0 )
		      BEGIN

				EXEC appgetstring_sp "STR_MCREVAL_GLACSUM_FAIL", @str_msg OUT

			        SELECT	@mcerror_msg = @str_msg + convert(varchar(5),@ret_status)

			        EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
				                                          @mcerror_msg, 0, @x_orig_flag, 1
              RETURN
		      END
          


          SELECT  @a1 = NULL, 
                  @a2 = NULL
       		SET ROWCOUNT  1                                     
       		SELECT  @a1 = unr_gain_acct, 
                  @a2 = unr_loss_acct    
       		FROM    glcocdt_vw                                 
          WHERE   @company_code = company_code
          AND     @nat_currency_code = currency_code
        	AND     @account_code LIKE acct_mask                

				  IF (@@ROWCOUNT = 0)
				  BEGIN
					  SET ROWCOUNT 0 

					EXEC appgetstring_sp "STR_MCREVAL_GAINLOSS_FAIL", @str_msg OUT

	  	 			SELECT @mcerror_msg = @str_msg
					  EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
						                                    @mcerror_msg, 0, @x_orig_flag, 1
            
            RETURN
				  END
			    SET ROWCOUNT 0 
          




				  SELECT @account_to_post = NULL
          IF  @amt_home_adjust > 0 
					  SELECT @account_to_post = @a1
				  ELSE
					  SELECT @account_to_post = @a2
    
          SELECT  @amt_home_adjust = -@amt_home_adjust,
                  @amt_oper_adjust = -@amt_oper_adjust

	


			
	SELECT @org_gain_loss_acct_revaluated = organization_id FROM glchart where account_code = @account_code
	SET @account_to_post = dbo.IBAcctMask_fn ( @account_to_post , @org_gain_loss_acct_revaluated )


          EXEC @ret_status = glacsum_sp
                        @gl_id,                 
                        @next_gl_jcc,           
                        @rec_company_code,      
                        @company_id,            
                        @account_to_post,       
                        @journal_description,   
                        ' ',                    
                        ' ',                    
                        ' ',                    
                        @amt_home_adjust,       
                        0,                      
                        @nat_currency_code,     
                        0,                      
                        @trx_type,              
                        0,                      
                        @amt_oper_adjust,   
                        0,                      
                        @rate_type_home,        
                        @rate_type_oper,       
                        ' ',                    
                        ' ',                    
                        ' ',                    
                        ' ',                    
                        0,                      
                        @error_flag OUTPUT      
			, @org_gain_loss_acct_revaluated 

			        IF ( @ret_status != 0 )
				      BEGIN

						EXEC appgetstring_sp "STR_MCREVAL_GLACSUM_FAIL", @str_msg OUT

					        SELECT	@mcerror_msg = @str_msg + convert(varchar(5),@ret_status)

					        EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
						                                     @mcerror_msg, 0, @x_orig_flag, 1
                 
                  RETURN
				      END

                        
      END
      
      SELECT @revaled_currency_code = @nat_currency_code

            
      


		  DELETE	CVO_Control..mcdist
		  WHERE	company_code = @company_code
		  AND	account_code = @account_code
		  AND	currency_code = @nat_currency_code
		  AND	balance_date = @balance_date

	  	IF (@@ROWCOUNT = 0)
		  BEGIN

			  EXEC appgetstring_sp "STR_MCDIST_NODELETE_ACCOUNT", @str_msg OUT

			  SELECT	@mcerror_msg = @str_msg + @account_code
			  EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key,
                           @x_user_id, @mcerror_msg, 0, @x_orig_flag, 1
        
			  RETURN
		  END

      


		  SELECT  @trx_done = @trx_done + 1
		  SELECT  @perc_done = (@trx_done / @total_trx) * 100

		EXEC appgetstring_sp "STR_PROCESSING", @str_msg OUT

  		EXEC CVO_Control..status_sp "MCREVAL", @x_proc_key, @x_user_id,
                        @str_msg, @perc_done, @x_orig_flag, 0
	END
GO
GRANT EXECUTE ON  [dbo].[mcreval_sp] TO [public]
GO
