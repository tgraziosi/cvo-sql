SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glbalchk.SPv - e7.2.2 : 1.9
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

 








 



					 










































 































































































































































































































































































































































































































































































































































































 




























CREATE PROCEDURE [dbo].[glbalchk_sp] 
			@action varchar(7) = "REPORT",
			@silent smallint = 0,
			@debug smallint = 0
			
AS

BEGIN

	DECLARE @result int,
			@period_end int,
			@year_start int,
			@year_end int,
			@fmt_date varchar(24),
			@fmt_date1 varchar(24),
			@errors_found smallint

	CREATE TABLE #baluntil (
			account_code varchar(32) 	NOT NULL,
			balance_type smallint	NOT NULL,
			currency_code varchar(8)	NOT NULL,
			balance_until int	 NOT NULL)
			
	CREATE UNIQUE INDEX #baluntil_ind_0
	ON #baluntil ( account_code,
					balance_type,
					currency_code,
					balance_until )

	IF ( @silent = 0 )
	BEGIN
		SELECT "********************************************************************"
		SELECT "***        General Ledger Balance Table Consistency Checker      ***"
		SELECT "***       Version 1.0, Copyright Platinum Software Corp. 1995    ***"
		SELECT "********************************************************************"
	END
	
	SELECT @errors_found = 0
	
	
	IF ( @silent = 0 AND @action = "REPAIR" )
	BEGIN
		SELECT "***  Repair Option Selected ***"
		SELECT "***  Checking for NULL values in balance_until column"
	END
	
	IF EXISTS( SELECT *
			FROM glbal
			WHERE ISNULL( balance_until, -1 ) = -1 )
	BEGIN
		IF ( @silent = 0 )
		BEGIN
			SELECT @errors_found = 1
			SELECT "***  NULL values found in balance_until column!"
			SELECT convert(char(33), "account_code" )+
				convert(char(13), "balance_type" )+
				convert(char(14), "currency_code" )+
				convert(char(13), "balance_date" )
			SELECT convert(char(33), account_code )+
				convert(char(13), balance_type )+ 
				convert(char(14), currency_code )+
				convert(char(13), balance_date )
			FROM glbal
			WHERE ISNULL( balance_until, -1 ) = -1
		END
		
		IF ( @action = "REPAIR" )
		BEGIN
			IF ( @silent = 0 )
				SELECT "*** Updating GLBAL ***"
			SET ROWCOUNT 4096
			WHILE 1=1
			BEGIN
				UPDATE glbal
				SET balance_until = 0
				WHERE ISNULL( balance_until, -1 ) = -1
				
				IF ( @@ROWCOUNT < 4096 )
					break
			END
			SET ROWCOUNT 0
		END
	END
	
	SELECT @period_end = MIN( balance_date )
	FROM glbal
	
	SELECT @year_end = MIN( period_end_date )
	FROM glprd
	WHERE period_end_date >= @period_end
	AND period_type = 1003
	
	WHILE ( @period_end IS NOT NULL )
	BEGIN 
		DELETE #baluntil
		
		EXEC glfmtdt_sp @period_end, @fmt_date OUTPUT
		
		IF ( @silent = 0 )
		BEGIN
			SELECT "***  Validating  period: "+@fmt_date
		END
		
		IF ( @period_end = @year_end )
		BEGIN
			
			INSERT #baluntil (
					account_code,
					balance_type,
					currency_code,
					balance_until )
			SELECT account_code, 
					balance_type,
					currency_code, 
					MIN( balance_date) - 1
			FROM glbal
			WHERE balance_date > @period_end
			AND bal_fwd_flag = 1
			GROUP BY account_code, balance_type, currency_code
		END
		
		ELSE
		BEGIN
			INSERT #baluntil (
					account_code,
					balance_type,
					currency_code,
					balance_until )
			SELECT account_code, 
					balance_type,
					currency_code, 
					MIN( balance_date) - 1
			FROM glbal
			WHERE balance_date > @period_end
			AND (bal_fwd_flag = 1 or balance_date <= @year_end )
			GROUP BY account_code, balance_type, currency_code
		END
		
		IF EXISTS( SELECT *
				FROM #baluntil u, glbal b
				WHERE u.account_code = b.account_code
				AND u.balance_type = b.balance_type
				AND u.currency_code = b.currency_code
				AND b.balance_date = @period_end
				AND u.balance_until != b.balance_until )
		BEGIN
			IF ( @silent = 0 )
			BEGIN
				SELECT @errors_found = 1
				SELECT "***  Inconsistent GLBAL records found for period!"
				SELECT convert(char(33), "account_code" )+
					convert(char(13), "balance_type" )+
					convert(char(14), "currency_code" )+
					convert(char(13), "balance_date" )+
					convert(char(14), "balance_until" )+
					convert(char(22), "correct_balance_until" )
				SELECT convert(char(33), b.account_code )+
					convert(char(13), b.balance_type )+ 
					convert(char(14), b.currency_code )+
					convert(char(13), b.balance_date )+
					convert(char(14), b.balance_until )+
					convert(char(22), u.balance_until )
				FROM #baluntil u, glbal b
				WHERE u.account_code = b.account_code
				AND u.balance_type = b.balance_type
				AND u.currency_code = b.currency_code
				AND b.balance_date = @period_end
				AND u.balance_until != b.balance_until
			END
			
			IF ( @action = "REPAIR" )
			BEGIN
				IF ( @silent = 0 )
					SELECT "*** Updating GLBAL ***"
				SET ROWCOUNT 4096
				WHILE 1=1
				BEGIN
					UPDATE glbal
					SET balance_until = u.balance_until
					FROM #baluntil u, glbal b
					WHERE u.account_code = b.account_code
					AND u.balance_type = b.balance_type
					AND u.currency_code = b.currency_code
					AND b.balance_date = @period_end
				 	AND u.balance_until != b.balance_until
					
					IF ( @@ROWCOUNT < 4096 )
						break
				END
				SET ROWCOUNT 0
			END
		END
		
		ELSE IF ( @silent = 0 )
		BEGIN
			SELECT "***  GLBAL OK"
		END
		
		SELECT @period_end = MIN( balance_date )
		FROM glbal
		WHERE balance_date > @period_end

		SELECT @year_end = MIN( period_end_date )
		FROM glprd
		WHERE period_end_date >= @period_end
		AND period_type = 1003
	
	END
	
	SELECT @year_end = MIN( period_end_date )
	FROM glprd
	WHERE period_type = 1003
	
	SELECT @year_start = MIN( period_start_date )
	FROM glprd
	WHERE period_type = 1001
	
	WHILE ( @year_end IS NOT NULL )
	BEGIN
		DELETE #baluntil
		
		EXEC glfmtdt_sp @year_start, @fmt_date OUTPUT
		EXEC glfmtdt_sp @year_end, @fmt_date1 OUTPUT
		
		IF ( @silent = 0 )
			SELECT "***  Validating Non-Forwarding Accounts in Fiscal year: "+@fmt_date+" to  "+@fmt_date1
		
		INSERT #baluntil (
				account_code,
				balance_type,
				currency_code,
				balance_until )
		SELECT b.account_code, 
				b.balance_type,
				b.currency_code, 
				MAX(b.balance_date)
		FROM glbal b, glprd p
		WHERE b.bal_fwd_flag = 0
		AND b.balance_date 
		BETWEEN @year_start AND @year_end
		GROUP BY b.account_code, b.balance_type, b.currency_code
		
		IF EXISTS( SELECT *
				FROM #baluntil u, glbal b
				WHERE u.account_code = b.account_code
				AND u.balance_type = b.balance_type
				AND u.currency_code = b.currency_code
				AND u.balance_until = b.balance_date
				AND b.balance_until != @year_end )
		BEGIN
			IF ( @silent = 0 )
			BEGIN
				SELECT @errors_found = 1
				SELECT "***  Inconsistencies found in GLBAL"
				SELECT convert(char(33), "account_code" )+
					convert(char(13), "balance_type" )+
					convert(char(14), "currency_code" )+
					convert(char(13), "balance_date" )+
					convert(char(14), "balance_until" )+
					convert(char(22), "correct_balance_until" )
				SELECT convert(char(33), b.account_code )+
					convert(char(13), b.balance_type )+ 
					convert(char(14), b.currency_code )+
					convert(char(13), b.balance_date )+
					convert(char(14), b.balance_until )+
					convert(char(22), @year_end )
				FROM #baluntil u, glbal b
				WHERE u.account_code = b.account_code
				AND u.balance_type = b.balance_type
				AND u.currency_code = b.currency_code
				AND u.balance_until = b.balance_date
				AND b.balance_until != @year_end
			END
			
			IF ( @action = "REPAIR" )
			BEGIN
				IF ( @silent = 0 )
					SELECT "*** Updating GLBAL ***"
				SET ROWCOUNT 4096
				WHILE 1=1
				BEGIN
				
					UPDATE glbal
					SET balance_until = @year_end
					FROM #baluntil u, glbal b
					WHERE u.account_code = b.account_code
					AND u.balance_type = b.balance_type
					AND u.currency_code = b.currency_code
					AND u.balance_until = b.balance_date
					AND b.balance_until != @year_end
				
					IF ( @@ROWCOUNT < 4096 )
						break
				END
				SET ROWCOUNT 0
			END
		END
		
		ELSE IF ( @silent = 0 )
		BEGIN
			SELECT "***  GLBAL OK"
		END
		
		SELECT @year_end = MIN( period_end_date )
		FROM glprd
		WHERE period_type = 1003
		AND period_end_date > @year_end
		
		SELECT @year_start = MIN( period_start_date )
		FROM glprd
		WHERE period_type = 1001
		AND period_start_date > @year_start
		
	END

	DELETE #baluntil
	
	IF ( @silent = 0 )
		SELECT "***  Validating Forwarding Accounts"
		
	INSERT #baluntil (
			account_code,
			balance_type,
			currency_code,
			balance_until )
	SELECT account_code, 
			balance_type,
			currency_code, 
			MAX(balance_date)
	FROM glbal
	WHERE bal_fwd_flag = 1
	GROUP BY account_code, balance_type, currency_code
	
	IF EXISTS( SELECT *
			FROM #baluntil u, glbal b
			WHERE u.account_code = b.account_code
			AND u.balance_type = b.balance_type
			AND u.currency_code = b.currency_code
			AND u.balance_until = b.balance_date
			AND b.balance_until != 999999 )
	BEGIN
		IF ( @silent = 0 )
		BEGIN
			SELECT @errors_found = 1
			SELECT "***  Inconsistencies found in GLBAL"
			SELECT convert(char(33), "account_code" )+
				convert(char(13), "balance_type" )+
				convert(char(14), "currency_code" )+
				convert(char(13), "balance_date" )+
				convert(char(14), "balance_until" )+
				convert(char(22), "correct_balance_until" )
			SELECT convert(char(33), b.account_code )+
				convert(char(13), b.balance_type )+ 
				convert(char(14), b.currency_code )+
				convert(char(13), b.balance_date )+
				convert(char(14), b.balance_until )+
				convert(char(22), "999999" )
			FROM #baluntil u, glbal b
			WHERE u.account_code = b.account_code
			AND u.balance_type = b.balance_type
			AND u.currency_code = b.currency_code
			AND u.balance_until = b.balance_date
			AND b.balance_until != 999999
		END
			
		IF ( @action = "REPAIR" )
		BEGIN
			IF ( @silent = 0 )
				SELECT "*** Updating GLBAL ***"
			SET ROWCOUNT 4096	
			WHILE 1=1
			BEGIN
				UPDATE glbal
				SET balance_until = 999999
				FROM #baluntil u, glbal b
				WHERE u.account_code = b.account_code
				AND u.balance_type = b.balance_type
				AND u.currency_code = b.currency_code
				AND u.balance_until = b.balance_date
				AND b.balance_until != 999999
				
				IF ( @@ROWCOUNT < 4096 )
					break
			END
			SET ROWCOUNT 0
		END
		
		
	END
	
	ELSE IF ( @silent = 0 )
	BEGIN
		SELECT "***  GLBAL OK"
	END
	
	SET ROWCOUNT 0

	IF ( @errors_found = 0 )
	BEGIN
		IF ( @silent = 0 )
		BEGIN
			SELECT "********************************************************************"
			SELECT "***               Execution Complete:  No Errors Found           ***"
			SELECT "********************************************************************"
		END
		RETURN 0
	END
	
	ELSE
	BEGIN
		IF ( @silent = 0 )
		BEGIN
			SELECT "********************************************************************"
			SELECT "***               Execution Complete:  Errors Found!!            ***"
			SELECT "********************************************************************"
		END
		RETURN 1
	END
END
GO
GRANT EXECUTE ON  [dbo].[glbalchk_sp] TO [public]
GO
