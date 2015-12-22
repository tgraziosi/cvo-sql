SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE        [dbo].[glpsupd2_grp_sp] 
			@batch_code             varchar(16),
			@debug_level                    smallint = 0
			
AS

BEGIN

	DECLARE         @post_ctrl_num          varchar(16),
			@min_currency_code      varchar(8),                                             
			@post_user_id           smallint,
			@post_user_name         varchar(30),
			@period_end             int,    
			@work_time              datetime,
			@batch_type             smallint,
			@post_date              int,
			@start_time             datetime,
			@result                 int

	SELECT  @work_time = getdate(), @start_time = getdate()
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpsupd2_grp.cpp" + ", line " + STR( 129, 5 ) + " -- ENTRY: "

	


	EXEC    batinfo_group_sp      @batch_code,
				@post_ctrl_num  OUTPUT,
				@post_user_id   OUTPUT,
				@post_date      OUTPUT,
				@period_end     OUTPUT,
				@batch_type     OUTPUT
				
	








	






	INSERT  #updglbal (
		account_code,
		currency_code,
		balance_date,
		balance_until,
		balance_type,
		current_balance,
		home_current_balance,
		bal_fwd_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		account_type,
		current_balance_oper )
	SELECT  b.account_code,
		b.currency_code,
		@period_end,
		b.balance_until,
		b.balance_type,
		b.current_balance,
		b.home_current_balance,
		b.bal_fwd_flag,
		b.seg1_code,
		ISNULL( b.seg2_code, " " ),
		ISNULL( b.seg3_code, " " ),
		ISNULL( b.seg4_code, " " ),
		b.account_type,
		b.current_balance_oper
	FROM    #acct t, glbal b WITH (HOLDLOCK)
	WHERE   t.account_code = b.account_code
	AND     t.balance_type = b.balance_type
	AND     b.balance_until >= @period_end
	AND     b.balance_date < @period_end

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 4 )
	BEGIN
		SELECT  "Forwarded balance:"+
			convert( char(35), "account_code" ) +
			convert( char(15), "currency_code" ) +
			convert( char(15), "balance_date" ) +
			convert( char(15), "bal_fwd_flag" ) +
			convert( char(15), "current_bal" ) +
			convert( char(15), "home_cur_bal" )+
			convert( char(15), "home_cur_bal" )
		SELECT  "Forwarded balance:"+
			convert( char(35), account_code ) +
			convert( char(15), currency_code ) +
			convert( char(15), balance_date ) +
			convert( char(15), bal_fwd_flag ) +
			convert( char(25), ROUND(current_balance, 2) ) +
			convert( char(25), ROUND(home_current_balance, 2) ) +
			convert( char(25), ROUND(current_balance_oper, 2) )
		FROM    #updglbal
	END

	IF ( @debug_level > 2 ) SELECT "glpsupd2_grp.cpp" + ", line " + STR( 216, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Insert prior period records into #updglbal"

	




	UPDATE  t
	SET     initialized = 1
	FROM    #drcr t, #updglbal b
	WHERE   t.account_code = b.account_code
	AND     t.currency_code = b.currency_code
	AND     t.balance_type = b.balance_type

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 2 ) SELECT "glpsupd2_grp.cpp" + ", line " + STR( 233, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Mark rows which already exist in #updglbal"
	





	INSERT  #updglbal (
		account_code,
		currency_code,
		balance_date,
		balance_until,
		balance_type,
		current_balance,
		home_current_balance,
		bal_fwd_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		account_type,
		current_balance_oper )
	SELECT  account_code,
		currency_code,
		@period_end,
		0, 
		balance_type,
		0.0,
		0.0,
		bal_fwd_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		account_type,
		0.0
	FROM    #drcr
	WHERE   initialized = 0

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 2 ) SELECT "glpsupd2_grp.cpp" + ", line " + STR( 275, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Insert missing records into #updglbal"
	






























	



	SELECT  @min_currency_code = MIN( b.currency_code )                     
	FROM    #drcr t, glbal b WITH (HOLDLOCK)                                                       
	WHERE   t.initialized = 0                                                                       
	AND     b.account_code = t.account_code                                                 
	AND     b.balance_type = t.balance_type                                                 
	AND     b.balance_date > @period_end                                                    

	INSERT  #updglbal (
		account_code,
		currency_code,
		balance_date,
		balance_until,
		balance_type,
		account_type,
		bal_fwd_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		current_balance,
		home_current_balance,
		current_balance_oper )
	SELECT  t.account_code,
		t.currency_code,
		b.balance_date,
		b.balance_until,
		t.balance_type,
		-1,
		t.bal_fwd_flag,
		" ",
		" ",
		" ",
		" ",
		0.0,
		0.0,
		0.0
	FROM    #drcr t, glbal b WITH(HOLDLOCK)
	WHERE   t.initialized = 0
	AND     b.account_code = t.account_code
	AND     b.balance_type = t.balance_type
	AND     b.balance_date > @period_end
                              
	GROUP BY t.account_code, t.currency_code, b.balance_date, b.balance_until, t.balance_type,
		 b.balance_type, b.account_code, t.initialized, t.bal_fwd_flag          

	IF ( @@error != 0 )
		GOTO rollback_trx

	UPDATE  b 
	SET     account_type = c.account_type,
		seg1_code = c.seg1_code,
		seg2_code = c.seg2_code,
		seg3_code = c.seg3_code,
		seg4_code = c.seg4_code,
		current_balance = 0.0,
		home_current_balance = 0.0,
		current_balance_oper = 0.0
	FROM    #updglbal b, glchart c
	WHERE   b.account_code = c.account_code
	AND     b.account_type = -1

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 2 ) SELECT "glpsupd2_grp.cpp" + ", line " + STR( 375, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Generate balance rows for future periods in #updglbal"
	










	IF ( @debug_level > 3 )
	BEGIN
		SELECT  "#updglbal records which already exist in GLBAL"
		SELECT  convert( char(35), "account_code") +
			convert( char(15), "currency_code") +
			convert( char(15), "balance_date") +
			convert( char(10), "bal_type") +
			convert( char(20), "current_balance")
			
		SELECT  convert( char(35), t.account_code) +
			convert( char(15), t.currency_code) +
			convert( char(15), t.balance_date) +
			convert( char(15), t.balance_type) +
			convert( char(25), ROUND(t.current_balance, 2))
		FROM    #updglbal t, glbal b 
		WHERE   b.account_code = t.account_code
		AND     b.currency_code = t.currency_code
		AND     b.balance_date = t.balance_date
		AND     b.balance_type = t.balance_type
	END

	DELETE  #updglbal
	FROM    glbal b, #updglbal t
	WHERE   b.account_code = t.account_code
	AND     b.currency_code = t.currency_code
	AND     b.balance_date = t.balance_date
	AND     b.balance_type = t.balance_type

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 3 )
	BEGIN
		SELECT  "#UPDGLBAL contents"
		SELECT  convert( char(35), "account_code") +
			convert( char(15), "currency_code") +
			convert( char(15), "balance_date") +
			convert( char(15), "balance_until") +
			convert( char(20), "current_balance")
			
		SELECT  convert( char(35), account_code) +
			convert( char(15), currency_code) +
			convert( char(15), balance_date) +
			convert( char(15), balance_until) +
			convert( char(25), ROUND(current_balance, 2))
		FROM    #updglbal
	END

	IF ( @debug_level > 3 ) SELECT "glpsupd2_grp.cpp" + ", line " + STR( 435, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Creating #UPDGLBAL"

	


	IF ( @debug_level > 1 ) SELECT "glpsupd2_grp.cpp" + ", line " + STR( 440, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting - No Error"
	RETURN 0

	rollback_trx:

	


	IF ( @debug_level > 1 ) SELECT "glpsupd2_grp.cpp" + ", line " + STR( 448, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting - Error"
	RETURN 1039

END
GO
GRANT EXECUTE ON  [dbo].[glpsupd2_grp_sp] TO [public]
GO
