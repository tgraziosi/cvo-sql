SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE        [dbo].[glpsupdt_grp_sp] 
			@batch_code             varchar(16),
			@debug_level                    smallint = 0
			
AS

BEGIN

	DECLARE         @post_ctrl_num          varchar(16),
			@post_user_id           smallint,
			@post_user_name         varchar(30),
			@period_end             int,    
			@year_begin             int,
			@year_end               int,
			@end_of_time            int,
			@work_time              datetime,
			@batch_type             smallint,
			@post_date              int,
			@start_time             datetime,
			@new_batch              varchar(16),
			@next_period_end        int,
			@company_code           varchar(8),
			@result                 int,
			@i                      int,
			@org_id					varchar(30),
			@batch_code_single			varchar(16)

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpsupdt_grp.cpp" + ", line " + STR( 189, 5 ) + " -- ENTRY: "
	SELECT  @work_time = getdate(), @start_time = getdate()


	CREATE TABLE #rates (   from_currency   varchar(8),
			to_currency     varchar(8),
			rate_type       varchar(8),
			date_applied    int,
			rate            float)

	CREATE TABLE #rate_info (       from_currency   varchar(8),
					to_currency     varchar(8),     
					rate_type       varchar(8), 
					date_applied    int,
					divide_flag     smallint,
					convert_date    int)
	
	EXEC    batinfo_group_sp      @batch_code,
				@post_ctrl_num  OUTPUT,
				@post_user_id   OUTPUT,
				@post_date      OUTPUT,
				@period_end     OUTPUT,
				@batch_type     OUTPUT
				
	



	SELECT  @year_begin = MAX(period_start_date)
	FROM    glprd
	WHERE   period_type = 1001
	AND     @period_end >= period_start_date

	SELECT  @year_end = MIN(period_end_date)
	FROM    glprd
	WHERE   period_type = 1003
	AND     @period_end <= period_end_date
	
	SELECT  @end_of_time = 999999

	



	CREATE TABLE    #baluntil (     account_code    varchar(32) NOT NULL,
					balance_type    smallint NOT NULL,
					balance_date    int NOT NULL,
					currency_code   varchar(8) NOT NULL,
					balance_until   int NOT NULL)
	IF ( @@error != 0 )
		return 1039

	CREATE INDEX    #baluntil_ind_0
	ON                      #baluntil (     account_code,
						balance_type,
						balance_date,
						currency_code )
	IF ( @@error != 0 )
		return 1039
	






	UPDATE  t 
	SET     initialized = 1
	FROM    #drcr t, glbal n
	WHERE   n.account_code = t.account_code
	AND     n.currency_code = t.currency_code
	AND     n.balance_type = t.balance_type
	AND     n.balance_date = @period_end

	IF ( @@error != 0 )
		return  1039

	IF ( @debug_level > 2 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 266, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Initialize #drcr for existing balances"
	


	INSERT  #acct(
		account_code,
		balance_type )
	SELECT DISTINCT
		account_code,
		balance_type
	FROM    #drcr
	WHERE   initialized = 0
	




	


	


	SELECT  @i = 0
	WHILE EXISTS(   SELECT  1
			FROM    master..syslockinfo
			WHERE   rsc_dbid = db_id()
			AND     rsc_type != 5
			AND     rsc_objid = object_id( "glbal") )
	BEGIN
		SELECT  "*** glpsupdt: Waiting to update glbal..."

		WAITFOR DELAY "00:00:10"
		
		SELECT  @i = @i + 1
		
		IF ( @i > 100 )
			RETURN  1070

	END
	
	BEGIN TRAN

	IF ( @debug_level > 2 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 309, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "******************* Beginning SQL Transaction ********************"
	



	EXEC    @result = glpsupd2_grp_sp @batch_code, @debug_level

	IF ( @result != 0 )
		GOTO rollback_trx
	


	INSERT  glbal ( 
		timestamp,
		account_code,
		currency_code,
		balance_date,
		balance_until,
		credit,
		debit,
		net_change,
		current_balance,
		balance_type,
		bal_fwd_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		account_type,
		home_credit,
		home_debit,
		home_net_change,
		home_current_balance,
		credit_oper,
		debit_oper,
		net_change_oper,
		current_balance_oper )
	SELECT  NULL,
		account_code,
		currency_code,
		balance_date,
		balance_until,
		0.0,
		0.0,
		0.0,
		current_balance,
		balance_type,
		bal_fwd_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		account_type,
		0.0,
		0.0,
		0.0,
		home_current_balance,
		0.0,
		0.0,
		0.0,
		current_balance_oper
	FROM    #updglbal

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 3 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 375, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "GLBAL insert of new records"
	


	UPDATE  b
	SET     b.credit                = b.credit + t.nat_credit, 
		b.debit                 = b.debit + t.nat_debit,
		b.net_change            = b.net_change + t.nat_debit - t.nat_credit,
		b.current_balance       = b.current_balance + 
						t.nat_debit - t.nat_credit,
		b.home_credit           = b.home_credit + t.home_credit,
		b.home_debit            = b.home_debit + t.home_debit,
		b.home_net_change       = b.home_net_change + 
						t.home_debit - t.home_credit,
		b.home_current_balance  = b.home_current_balance + 
						t.home_debit - t.home_credit,

		b.credit_oper           = b.credit_oper + t.oper_credit,
		b.debit_oper            = b.debit_oper + t.oper_debit,
		b.net_change_oper       = b.net_change_oper + 
						t.oper_debit - t.oper_credit,
		b.current_balance_oper  = b.current_balance_oper + 
						t.oper_debit - t.oper_credit

	FROM    glbal b, #drcr t
	WHERE   b.account_code = t.account_code
	AND     b.currency_code = t.currency_code
	AND     b.balance_date  = @period_end
	AND     b.balance_type  = t.balance_type

	IF ( @@error != 0 )
		GOTO rollback_trx

	



	UPDATE  b
	SET     b.current_balance       = b.current_balance + 
						t.nat_debit - t.nat_credit,
		b.home_current_balance  = b.home_current_balance + 
						t.home_debit - t.home_credit,
		b.current_balance_oper  = b.current_balance_oper + 
						t.oper_debit - t.oper_credit
	FROM    glbal b, #drcr t
	WHERE   b.account_code = t.account_code
	AND     b.currency_code = t.currency_code
	AND     ( b.bal_fwd_flag = 1 OR b.balance_date <= @year_end )
	AND     b.balance_date  > @period_end
	AND     b.balance_type  = t.balance_type

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 3 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 429, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Updating all balance records"
	





	INSERT          #baluntil (
			account_code,
			balance_date,
			balance_type,
			currency_code,
			balance_until )
			
	SELECT          c.account_code, 
			c.balance_date, 
			c.balance_type,
			c.currency_code, 
			MIN( f.balance_date) - 1
	FROM            #updglbal c, glbal f WITH(HOLDLOCK)

	WHERE           c.account_code = f.account_code
	AND             c.balance_type = f.balance_type
	AND             c.balance_until = 0
	AND             c.currency_code = f.currency_code
	AND             @period_end < f.balance_date
	AND             (f.bal_fwd_flag = 1 or f.balance_date <= @year_end )
	GROUP BY        c.account_code, c.balance_date, c.balance_type, c.currency_code

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 3 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 461, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Time to generate #baluntil table"

	IF ( @debug_level > 4 )
	BEGIN
		SELECT  "*** GLPSUPDT contents of #baluntil table"
		SELECT  convert( char(35), "account_code" ) +
			convert( char(15), "balance_type" ) +
			convert( char(15), "balance_date" ) +
			convert( char(15), "currency_code" ) +
			convert( char(15), "balance_until" )
			
		SELECT  convert( char(35), account_code ) +
			convert( char(15), balance_type ) +
			convert( char(15), balance_date ) +
			convert( char(15), currency_code ) +
			convert( char(15), balance_until )
		FROM    #baluntil
		
		SELECT  @work_time = getdate()
	END
	





	IF ( @debug_level > 4 )
	BEGIN
		SELECT  "*** GLPSUPDT - glbal records to be updated with new balance_until data"
		SELECT  convert( char(35), "account_code" ) +
			convert( char(15), "balance_type" ) +
			convert( char(15), "balance_date" ) +
			convert( char(15), "currency_code" ) +
			convert( char(20), "glbal_balance_until" ) +
			convert( char(25), "#updglbal balance_until" )
			
		SELECT  convert( char(35), b.account_code ) +
			convert( char(15), b.balance_type ) +
			convert( char(15), b.balance_date ) +
			convert( char(15), b.currency_code ) +
			convert( char(20), b.balance_until ) +
			convert( char(25), u.balance_until )
		FROM    #updglbal u, glbal b
		WHERE   u.account_code = b.account_code
		AND     u.currency_code = b.currency_code
		AND     u.balance_until = b.balance_until
		AND     u.balance_type = b.balance_type
		AND     b.balance_until > 0
		AND     b.balance_date < @period_end
		
	END
	
	UPDATE  b
	SET     balance_until = @period_end-1
	FROM    #updglbal u, glbal b
	WHERE   u.account_code = b.account_code
	AND     u.currency_code = b.currency_code
	AND     u.balance_until = b.balance_until
	AND     u.balance_type = b.balance_type
	AND     b.balance_until > 0
	AND     b.balance_date < @period_end

	IF ( @@error != 0 )
		GOTO rollback_trx
		
	







	IF ( @debug_level > 4 )
	BEGIN
		SELECT  "*** GLPSUPDT - glbal records to be updated with new balance_until data"
		SELECT  convert( char(35), "account_code" ) +
			convert( char(15), "balance_type" ) +
			convert( char(15), "balance_date" ) +
			convert( char(15), "currency_code" ) +
			convert( char(20), "glbal_balance_until" ) +
			convert( char(24), "#baluntil balance_until" )
			
		SELECT  convert( char(35), b.account_code ) +
			convert( char(15), b.balance_type ) +
			convert( char(15), b.balance_date ) +
			convert( char(15), b.currency_code ) +
			convert( char(20), c.balance_until ) +
			convert( char(24), b.balance_until )
		FROM    #baluntil b, glbal c
		WHERE   c.account_code = b.account_code
		AND     c.balance_type = b.balance_type
		AND     c.balance_date = b.balance_date
		AND     c.currency_code = b.currency_code
	END

	UPDATE  c
	SET     c.balance_until = b.balance_until
	FROM    #baluntil b, glbal c
	WHERE   c.account_code = b.account_code
	AND     c.balance_type = b.balance_type
	AND     c.balance_date = b.balance_date
	AND     c.currency_code = b.currency_code

	IF ( @@error != 0 )
		GOTO rollback_trx
	





	IF ( @debug_level > 4 )
	BEGIN
		SELECT  "*** GLPSUPDT - glbal records to be updated with balance_until = 0"
		SELECT  convert( char(35), "account_code" ) +
			convert( char(15), "balance_type" ) +
			convert( char(15), "balance_date" ) +
			convert( char(15), "currency_code" ) +
			convert( char(20), "balance_until" )
			
		SELECT  convert( char(35), account_code ) +
			convert( char(15), balance_type ) +
			convert( char(15), balance_date ) +
			convert( char(15), currency_code ) +
			convert( char(20), balance_until )
		FROM    glbal
		WHERE   balance_until = 0
	END

	UPDATE  glbal
	SET     balance_until = (@end_of_time*bal_fwd_flag + @year_end*(1-bal_fwd_flag))
	WHERE   balance_until = 0

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 3 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 598, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Updating balance_until column"
	



	UPDATE  h
	SET     posted_flag = 1,
		date_posted = @post_date
	FROM    gltrx h, #gldtrx t
	WHERE   h.journal_ctrl_num = t.journal_ctrl_num

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 3 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 612, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Updating posted flag for transaction group"
	



	UPDATE  d
	SET     posted_flag = 1,
		date_posted = @post_date
	FROM    gltrxdet d, #gldtrx t
	WHERE   d.journal_ctrl_num = t.journal_ctrl_num

	IF ( @@error != 0 )
		GOTO rollback_trx

	IF ( @debug_level > 3 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 626, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Updating posted flag for transaction details"

	SELECT  @post_user_name = user_name
	FROM    glusers_vw
	WHERE   user_id = @post_user_id
	
	



	
	IF EXISTS(      SELECT  1
			FROM    #gldtrx
			WHERE  (repeating_flag = 1
			OR      reversing_flag = 1
			OR      recurring_flag = 1))
	BEGIN

		CREATE TABLE #TEMP(
			key_table INTEGER IDENTITY (1,1),
			batch_ctrl_num_group char(16), 
			process_group_num varchar(16),
			batch_ctrl_num char(16))

		INSERT INTO #TEMP (batch_ctrl_num_group, process_group_num, batch_ctrl_num)
		SELECT batch_ctrl_num_group, process_group_num, batch_ctrl_num
		FROM #Group_batch
		WHERE batch_ctrl_num_group = @batch_code

		CREATE TABLE #gldtrx_grp
		(
			journal_ctrl_num      		varchar(16)	NOT NULL, 
			batch_code			varchar(16)	NOT NULL,
			date_applied          		int	NOT NULL,
			recurring_flag			smallint	NOT NULL,
			repeating_flag			smallint	NOT NULL,
			reversing_flag			smallint	NOT NULL,
			mark_flag           		smallint	NOT NULL, 	
			interbranch_flag		smallint	NOT NULL
		)

		CREATE UNIQUE CLUSTERED	INDEX	#gldtrx_grp_ind_0
		ON				#gldtrx_grp ( journal_ctrl_num )
		
		CREATE INDEX	#gldtrx_grp_ind_1
		ON		#gldtrx_grp ( mark_flag )

		DECLARE @key_table INT
		SET @key_table = 0

		SELECT  @key_table = MIN(key_table)
		FROM    #TEMP
		WHERE   key_table > @key_table

		WHILE @key_table IS NOT NULL
		BEGIN
			SELECT  @new_batch = " "

			DELETE #gldtrx_grp

			SELECT  @next_period_end = MIN( period_end_date )
			FROM    glprd
			WHERE   period_end_date > @period_end
			
			IF EXISTS(      SELECT  1
					FROM    glco
					WHERE   batch_proc_flag = 1 )
			   AND
			   EXISTS(      SELECT  1
					FROM    #gldtrx
					WHERE  (repeating_flag = 1
					OR      reversing_flag = 1))
			BEGIN
				SELECT  @company_code = BAT.company_code,
						@org_id		  = BAT.org_id,
						@batch_code_single	  = BAT.batch_ctrl_num
				FROM    batchctl BAT
					INNER JOIN #TEMP GRP ON BAT.batch_ctrl_num = GRP.batch_ctrl_num
				WHERE GRP.key_table = @key_table
				
				EXEC @result =  glnxtbat_sp     6000,
								@batch_code_single,	
								6010,
								@post_user_name,
								@next_period_end,
								@company_code,
								@new_batch OUTPUT,
								@org_id

				IF ( @result != 0 )
					goto rollback_trx
			END

			INSERT INTO #gldtrx_grp
			SELECT a.journal_ctrl_num, b.batch_code, a.date_applied, a.recurring_flag, a.repeating_flag, a.reversing_flag, 
			       a.mark_flag, a.interbranch_flag 
			FROM #gldtrx a INNER JOIN gltrx b ON ( a.journal_ctrl_num = b.journal_ctrl_num ) INNER JOIN #TEMP c ON (  b.batch_code = c.batch_ctrl_num )
			WHERE c.key_table = @key_table

			EXEC @result = glmkrec_sp       @period_end, 
							@new_batch,
							@post_date,
							@debug_level
			IF ( @result != 0 )
				goto rollback_trx

			SELECT  @key_table = MIN(key_table)
			FROM    #TEMP
			WHERE   key_table > @key_table
		END

		DROP TABLE #TEMP
		DROP TABLE #gldtrx_grp
	END
	


	EXEC    batupdst_grp_sp     @batch_code, 1
	


	COMMIT TRAN 

	IF ( @debug_level > 2 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 723, 5 ) + " -- MSG: " + CONVERT(char,@start_time,100) + "******************  End SQL Transaction ******************"
	


	DROP TABLE      #baluntil
	DROP TABLE      #rates
	DROP TABLE      #rate_info

	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpsupdt_grp.cpp" + ", line " + STR( 734, 5 ) + " -- EXIT: "
	RETURN 0

	


	rollback_trx:

	



	ROLLBACK TRAN
	


	IF ( @debug_level > 0 ) SELECT "glpsupdt_grp.cpp" + ", line " + STR( 750, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting - ERROR"
	RETURN 1039

	




END
GO
GRANT EXECUTE ON  [dbo].[glpsupdt_grp_sp] TO [public]
GO
