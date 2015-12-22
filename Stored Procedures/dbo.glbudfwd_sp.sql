SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[glbudfwd_sp]
	@budget_code	varchar(16),
	@current_period	int,
	@year_end	int,
	@year_start	int

AS 
DECLARE @new_current 		float, 
	
	@old_amt 		float, 	
	@diff 			float, 
	@old_net 		float, 
	@net 			float, 	
	@account 		varchar(32), 
        @lastacct       	varchar(32),
        @old_amt_nat    	float,  
        @diff_nat       	float, 
        @old_net_nat    	float, 
        @net_nat        	float,  
        @old_amt_oper   	float,  
        @diff_oper      	float, 
        @old_net_oper   	float, 
        @net_oper       	float,
        @new_current_nat 	float,  
        @new_current_oper 	float,
        @nat_cur_code  		varchar(8),
        



        @rate   		float,
        @rate_oper      	float,
        @reference_code 	varchar(32)	

 
CREATE TABLE #glbudtmp
(
	sequence_id	int,	
        budget_code     varchar(16)		NOT NULL,
        account_code    varchar(32)		NOT NULL,
        reference_code  varchar(32)		NULL,		
        net_change      float			NOT NULL,
        current_balance	float			NOT NULL,
        period_end_date int			NOT NULL,
	seg1_code	varchar(32) 		NULL,
	seg2_code	varchar(32) 		NULL,
	seg3_code	varchar(32) 		NULL,
	seg4_code	varchar(32) 		NULL,
        changed_flag    smallint                NOT NULL,
        nat_cur_code            varchar(8),
        



        rate                    float,
        rate_oper               float,
        nat_net_change          float,
        nat_current_balance     float,
        net_change_oper         float,
        current_balance_oper    float                  
)

SELECT  @account = '', @lastacct = ''





WHILE ( 1 = 1 )
BEGIN
	SET	ROWCOUNT 500

	INSERT	#glbudtmp (
		sequence_id	,
		budget_code     ,
		account_code    ,
		reference_code	,	
		net_change      ,
		current_balance ,
		period_end_date ,
		seg1_code	,
		seg2_code	,
		seg3_code	,
		seg4_code,
                changed_flag,
                nat_cur_code       ,
                



                rate                ,
                rate_oper           ,
                nat_net_change      ,
                nat_current_balance ,
                net_change_oper     ,
                current_balance_oper
 )
	SELECT 	sequence_id	,
		budget_code     ,
		account_code    ,
		reference_code 	,	
		net_change      ,
		current_balance ,
		period_end_date ,
		seg1_code	,
		seg2_code	,
		seg3_code	,
		seg4_code	,
                changed_flag    ,
                nat_cur_code       ,
                



                rate                ,
                rate_oper           ,
                nat_net_change      ,
                nat_current_balance ,
                net_change_oper     ,
                current_balance_oper

	FROM 	glbuddet
	WHERE 	budget_code = @budget_code
	AND	period_end_date = @current_period
	AND	account_code > @lastacct
	ORDER BY account_code
				
	IF ( @@ROWCOUNT < 500 )
		BREAK

	SELECT 	@lastacct = MAX( account_code )
	FROM	#glbudtmp

END













DECLARE glbuddet_save CURSOR FOR 




	SELECT	account_code, reference_code, net_change, nat_net_change,	
		net_change_oper, nat_cur_code, rate, rate_oper
	FROM 	#glbuddet							
	WHERE	budget_code = @budget_code					
	  AND	period_end_date = @current_period				
	  AND	changed_flag = 1						





SELECT  @account = NULL, @reference_code = NULL,
	@old_amt = 0, @new_current = 0, 
	@old_net = 0, @net = 0, @old_amt_nat = 0,
	@new_current_nat = 0, @old_net_nat = 0, @net_nat = 0,
	@old_amt_oper = 0, @new_current_oper = 0, @old_net_oper = 0, @net_oper = 0


OPEN glbuddet_save


FETCH NEXT FROM glbuddet_save INTO @account, @reference_code, @net, @net_nat, @net_oper, @nat_cur_code, @rate, @rate_oper

WHILE @@FETCH_STATUS = 0
BEGIN
   	















   	






	


	IF NOT EXISTS ( SELECT	budget_code
			FROM	glbuddet
		   	WHERE   budget_code = @budget_code
		   	AND	account_code = @account
		   	AND  	period_end_date = @current_period 
		   	AND 	reference_code = @reference_code)		
	BEGIN
		


		SELECT  @diff = @net,
			@diff_nat = @net_nat,
			@diff_oper = @net_oper
		








	   	INSERT 	glbuddet( 
			sequence_id,	budget_code,	account_code, reference_code, 	
		        net_change,	current_balance,period_end_date,
			seg1_code,	seg2_code,	seg3_code,
                        seg4_code,      changed_flag,   nat_cur_code,
			 rate,
                        rate_oper,      nat_net_change, nat_current_balance,
                        net_change_oper,current_balance_oper)
		SELECT	sequence_id, 	budget_code, 	account_code, reference_code, 	
			net_change, 	current_balance,period_end_date,
			seg1_code,	seg2_code,	seg3_code,
                        seg4_code,      0,   nat_cur_code,
                         rate,
                        rate_oper,      nat_net_change, nat_current_balance,
                        net_change_oper,current_balance_oper
	   	FROM 	#glbuddet
   		WHERE	account_code = @account
	   	AND	budget_code = @budget_code
   		AND	period_end_date = @current_period
		AND	reference_code = @reference_code		
	END
	ELSE
	BEGIN
	   	


                SELECT  @old_amt = isnull( SUM(net_change), 0 ),
                        @old_amt_nat = isnull( SUM(nat_net_change), 0 ),
                        @old_amt_oper = isnull( SUM(net_change_oper), 0 )
		FROM 	glbuddet
		WHERE	account_code = @account
		AND	budget_code = @budget_code
		AND	reference_code = @reference_code		
		AND	period_end_date > @year_start
		AND	period_end_date < @current_period

		


                SELECT  @new_current = isnull( @old_amt, 0 ) + @net,
                        @new_current_nat = isnull( @old_amt_nat, 0 ) + @net_nat,
                        @new_current_oper = isnull( @old_amt_oper, 0 ) + @net_oper

		


                SELECT  @old_net = isnull( net_change, 0 ),
                        @old_net_nat = isnull( nat_net_change, 0 ),
                        @old_net_oper = isnull( net_change_oper, 0 )
	   	FROM 	glbuddet
   		WHERE	account_code = @account
	   	AND	budget_code = @budget_code
   		AND	period_end_date = @current_period
		AND	reference_code = @reference_code		

                SELECT  @diff = @net - @old_net,
                        @diff_nat = @net_nat - @old_net_nat,
                        @diff_oper = @net_oper - @old_net_oper

		


	   	UPDATE 	glbuddet
   		SET	current_balance = @new_current,
   			reference_code =@reference_code,		
                        net_change = @net,
                        nat_current_balance = @new_current_nat,
                        nat_net_change = @net_nat,
                        current_balance_oper = @new_current_oper,
                        net_change_oper = @net_oper,
                        nat_cur_code = @nat_cur_code,
                        



                        rate = @rate,
                        rate_oper = @rate_oper
	   	WHERE	account_code = @account
   		AND	budget_code = @budget_code
	   	AND	period_end_date = @current_period
	   	AND	reference_code = @reference_code		

		



		DELETE	#glbuddet
		WHERE	account_code = @account
	   	AND	period_end_date = @current_period
	   	AND	reference_code = @reference_code		
	END
			                                                                                                  
   	


   	UPDATE 	glbuddet
        SET     current_balance = ( current_balance + @diff ),
                nat_current_balance = ( nat_current_balance + @diff_nat ),
                current_balance_oper = ( current_balance_oper + @diff_oper )
   	WHERE	account_code = @account
   	AND	budget_code = @budget_code
   	AND	reference_code = @reference_code		
   	AND	period_end_date > @current_period
   	AND	period_end_date < @year_end

	


	DELETE #glbudtmp WHERE account_code = @account AND reference_code = @reference_code		
	
	FETCH NEXT FROM glbuddet_save INTO @account, @reference_code, @net, @net_nat, @net_oper, @nat_cur_code, @rate, @rate_oper
END

CLOSE glbuddet_save

DEALLOCATE glbuddet_save






SELECT  @account = '', @diff = 0,@diff_nat = 0, @diff_oper = 0






DECLARE glbuddet_delete CURSOR FOR 




	SELECT	account_code, reference_code, net_change, nat_net_change,
		net_change_oper
	FROM 	#glbudtmp t1
	WHERE	t1.budget_code = @budget_code
	  AND	t1.period_end_date = @current_period





OPEN glbuddet_delete
FETCH NEXT FROM glbuddet_delete INTO @account, @reference_code, @diff, @diff_nat, @diff_oper

WHILE @@FETCH_STATUS = 0
BEGIN
   	


   	

	



	













   	


   	
	
	IF NOT EXISTS (SELECT 1 FROM #glbuddet WHERE period_end_date = @current_period AND account_code = @account AND reference_code = @reference_code)
	BEGIN
   	  


   	  UPDATE 	glbuddet
          SET     current_balance = ( current_balance - @diff ),
                  nat_current_balance = ( nat_current_balance - @diff_nat ),
                  current_balance_oper = ( current_balance_oper - @diff_oper )
   	  WHERE   account_code = @account
   	    AND   budget_code = @budget_code
   	    AND	reference_code = @reference_code		
   	    AND   period_end_date > @current_period
   	    AND   period_end_date < @year_end

	  DELETE glbuddet 
   	  WHERE  budget_code = @budget_code
   	    AND  period_end_date = @current_period
   	    AND  account_code = @account
   	    AND	reference_code = @reference_code		
   	END
   	FETCH NEXT FROM glbuddet_delete INTO @account, @reference_code, @diff, @diff_nat, @diff_oper
END

CLOSE glbuddet_delete

DEALLOCATE glbuddet_delete

GO
GRANT EXECUTE ON  [dbo].[glbudfwd_sp] TO [public]
GO
