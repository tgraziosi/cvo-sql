SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO






CREATE  PROCEDURE [dbo].[glpspost_grp_sp]   @batch_code     varchar(16),
				@debug_level    smallint = 0
	WITH RECOMPILE
AS

BEGIN

	DECLARE @result                 int,
		@work_time              datetime,
		@start_time             datetime,
		@prec                   smallint,
		@post_ctrl_num          varchar(16),
		@post_user_id           int,
		@post_date              int,
		@period_end             int,
		@batch_type             smallint,
		@prec_oper              smallint
		
	SELECT  @work_time = getdate(), @start_time = getdate()
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpspost_grp.cpp" + ", line " + STR( 128, 5 ) + " -- ENTRY: "
	




	


	EXEC    batinfo_group_sp      @batch_code,
				@post_ctrl_num  OUTPUT,
				@post_user_id   OUTPUT,
				@post_date      OUTPUT,
				@period_end     OUTPUT,
				@batch_type     OUTPUT

	



	SELECT  @prec = curr_precision
	FROM    glcurr_vw m, glco c
	WHERE   m.currency_code = c.home_currency
	



	SELECT  @prec_oper = curr_precision
	FROM    glcurr_vw m, glco c
	WHERE   m.currency_code = c.oper_currency
	




	














	SELECT  @work_time = getdate()

	SELECT  account_code, 
		nat_cur_code                                            currency_code,
		ROUND( ABS( SUM(balance * (sign(balance) + 1)/2) ), 
			@prec)                                          home_debit,
		ROUND( ABS( SUM(balance * (sign(balance) - 1)/2) ), 
			@prec)                                          home_credit,
		ROUND( ABS( SUM(nat_balance * (sign(nat_balance) + 1)/2) ), 
			p.curr_precision)                                          nat_debit,
		ROUND( ABS( SUM(nat_balance * (sign(nat_balance) - 1)/2) ), 
			p.curr_precision)                                          nat_credit,
		ROUND( ABS( SUM(balance_oper * (sign(balance_oper) + 1)/2) ), 
			@prec_oper)                                          oper_debit,
		ROUND( ABS( SUM(balance_oper * (sign(balance_oper) - 1)/2) ), 
			@prec_oper)                                          oper_credit
	INTO    #sumtemp
	FROM    #gldtrdet d, glcurr_vw p
	WHERE	d.nat_cur_code = p.currency_code
	GROUP BY account_code, nat_cur_code, curr_precision

	IF ( @@error != 0 )
		return  1039

	INSERT  #drcr ( account_code, 
			currency_code,
			balance_type, 
			home_debit, 
			home_credit,
			nat_debit,
			nat_credit,
			bal_fwd_flag,
			seg1_code,
			seg2_code,
			seg3_code,
			seg4_code,
			account_type,
			initialized,
			oper_debit,
			oper_credit )

	SELECT          t.account_code,
			t.currency_code,
			1, 
			t.home_debit,
			t.home_credit,
			t.nat_debit,
			t.nat_credit,
			( SIGN( s.account_type - 400 ) - 1 ) / -2, 
			s.seg1_code,
			ISNULL( s.seg2_code, " " ),
			ISNULL( s.seg3_code, " " ),
			ISNULL( s.seg4_code, " " ),
			s.account_type,
			0,
			t.oper_debit,
			t.oper_credit
	FROM            #sumtemp t, glchart s
	WHERE           t.account_code = s.account_code

	IF ( @@error != 0 )
		return  1039

	DROP TABLE      #sumtemp

	IF ( @debug_level > 2 ) SELECT "glpspost_grp.cpp" + ", line " + STR( 243, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Summing debits and credits"

	IF ( @debug_level > 4 )
	BEGIN
		SELECT  "Contents of temp table #drcr (summarized detail totals)"
		
		SELECT  convert( char(35), "account_code" ) +
			convert( char(15), "currency_code" ) +
			convert( char(15), "balance_type" ) +
			convert( char(25), "nat_credit" ) +
			convert( char(25), "nat_debit" ) +
			convert( char(25), "home_credit" ) +
			convert( char(25), "home_debit" )  +
			convert( char(25), "oper_credit" ) +
			convert( char(25), "oper_debit" )
			
		SELECT  convert( char(35), account_code ) +
			convert( char(15), currency_code ) +
			convert( char(15), balance_type ) +
			convert( char(25), ROUND(nat_credit, 2) ) +
			convert( char(25), ROUND(nat_debit, 2) ) +
			convert( char(25), ROUND(home_credit, 2) ) +
			convert( char(25), ROUND(home_debit, 2) )+
			convert( char(25), ROUND(oper_credit, 2) ) +
			convert( char(25), ROUND(oper_debit, 2) )
		FROM    #drcr

	END
	















	SELECT  s.summary_code                                          account_code, 
		s.summary_type                                          summary_type,
		d.currency_code                                         currency_code,
		ROUND( SUM( SIGN(s.summary_type) * d.home_debit  -
		   SIGN(SIGN(s.summary_type) - 1) * d.home_credit), 
		   @prec)                                               home_debit,

		ROUND( SUM( SIGN(s.summary_type) * d.home_credit -
		   SIGN(SIGN(s.summary_type) - 1) * d.home_debit), 
		   @prec)                                               home_credit,

		ROUND( SUM( SIGN(s.summary_type) * d.nat_debit -
		   SIGN(SIGN(s.summary_type) - 1) * d.nat_credit), 
		   @prec)                                               nat_debit,
			
		ROUND( SUM( SIGN(s.summary_type) * d.nat_credit -
		   SIGN(SIGN(s.summary_type) - 1) * d.nat_debit), 
		   @prec)                                               nat_credit,
		ROUND( SUM( SIGN(s.summary_type) * d.oper_debit  -
		   SIGN(SIGN(s.summary_type) - 1) * d.oper_credit), 
		   @prec_oper)                                               oper_debit,

		ROUND( SUM( SIGN(s.summary_type) * d.oper_credit -
		   SIGN(SIGN(s.summary_type) - 1) * d.oper_debit), 
		   @prec_oper)                                               oper_credit

	INTO    #sumtemp1
	FROM    #drcr d, #summary s
	WHERE   d.account_code = s.account_code
	GROUP BY s.summary_code, s.summary_type, d.currency_code

	IF ( @@error != 0 )
		return  1039
	








	UPDATE  #drcr
	SET     home_debit  = d.home_debit  + t.home_debit,
		home_credit = d.home_credit + t.home_credit,
		nat_debit   = d.nat_debit   + t.nat_debit,
		nat_credit  = d.nat_credit  + t.nat_credit,
		oper_debit  = d.oper_debit  + t.oper_debit,
		oper_credit = d.oper_credit + t.oper_credit
	FROM    #drcr d, #sumtemp1 t
	WHERE   d.account_code = t.account_code
	AND d.currency_code = t.currency_code
	AND     t.summary_type IN ( 0, 1 )

	DELETE  #sumtemp1
	FROM    #drcr d, #sumtemp1 t
	WHERE   d.account_code = t.account_code
	AND     t.summary_type IN ( 0, 1 )

	INSERT  #drcr ( account_code, 
			currency_code,
			balance_type, 
			home_debit, 
			home_credit,
			nat_debit,
			nat_credit,
			bal_fwd_flag,
			seg1_code,
			seg2_code,
			seg3_code,
			seg4_code,
			account_type,
			initialized,
			oper_debit,
			oper_credit )
	SELECT          t.account_code,
			t.currency_code,
			s.balance_type,
			t.home_debit,
			t.home_credit,
			t.nat_debit,
			t.nat_credit,
			s.bal_fwd_flag,
			s.seg1_code,
			ISNULL( s.seg2_code, " " ),
			ISNULL( s.seg3_code, " " ),
			ISNULL( s.seg4_code, " " ),
			s.account_type,
			0,
			t.oper_debit,
			t.oper_credit
	FROM            #sumtemp1 t, #sumhdr s
	WHERE           t.account_code = s.summary_code
	AND             t.summary_type = s.summary_type

	IF ( @@error != 0 )
		return  1039

	DROP TABLE      #sumtemp1

	IF ( @debug_level > 2 ) SELECT "glpspost_grp.cpp" + ", line " + STR( 387, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Summarizing accounts"

	IF ( @debug_level > 4 )
	BEGIN
		SELECT  "Contents of temp table #drcr (summarized account totals)"
		
		SELECT  convert( char(35), "account_code" ) +
			convert( char(15), "currency_code" ) +
			convert( char(15), "balance_type" ) +
			convert( char(25), "nat_credit" ) +
			convert( char(25), "nat_debit" ) +
			convert( char(25), "home_credit" ) +
			convert( char(25), "home_debit" )  +
			convert( char(25), "oper_credit" ) +
			convert( char(25), "oper_debit" )
			
		SELECT  convert( char(35), account_code ) +
			convert( char(15), currency_code ) +
			convert( char(15), balance_type ) +
			convert( char(25), ROUND(nat_credit, 2) ) +
			convert( char(25), ROUND(nat_debit, 2) ) +
			convert( char(25), ROUND(home_credit, 2) ) +
			convert( char(25), ROUND(home_debit, 2) )+
			convert( char(25), ROUND(oper_credit, 2) ) +
			convert( char(25), ROUND(oper_debit, 2) )
		FROM    #drcr

	END

	




	





	EXEC    @result =       glpsupdt_grp_sp
				@batch_code,    
				@debug_level


	IF ( @debug_level > 1 )
	BEGIN
		IF ( @result != 0 )
		BEGIN
		
			SELECT  "Transaction group FAILED posting"
			SELECT  "Error code: " + STR(@result,8 )
			SELECT  "Error Text: " + e_ldesc
			FROM    glerrdef 
			WHERE   e_code = @result
			SELECT  "Execution Time: " +
				convert( char(20), datediff(ms, @start_time, getdate() )) + "ms"
		END
		
		ELSE
		BEGIN
			SELECT  "Transaction group posted SUCCESSFULLY"
			SELECT  "Execution Time: " +
				 convert( char(20), datediff(ms, @start_time, getdate() )) + "ms"
		END
	END        

	





	IF ( @debug_level > 3 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpspost_grp.cpp" + ", line " + STR( 460, 5 ) + " -- MSG: " + 'EXEC glpspstu_sp ' + CONVERT( varchar(10), @post_user_id ) + ', ' + CONVERT( varchar(10), @debug_level )

  	EXEC @result = glpspstu_sp 	@post_user_id,
                                @debug_level


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpspost_grp.cpp" + ", line " + STR( 466, 5 ) + " -- EXIT: "

	RETURN @result

END
GO
GRANT EXECUTE ON  [dbo].[glpspost_grp_sp] TO [public]
GO
