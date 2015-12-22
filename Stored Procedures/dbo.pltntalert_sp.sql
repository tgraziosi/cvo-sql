SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

	
CREATE PROCEDURE [dbo].[pltntalert_sp] 
(
	@debug_level	smallint	= 0	
)

AS

DECLARE 
	@alert_id 			int, 
	@sql 				char(255),
	@sql2 				char(255), 
	@sql3 				char(255), 
	@sql4 				char(255), 
	@alert_type 		char(1), 
	@activate 			int,
	@alert_recs 		int, 
	@de1 				varchar(100), 
	@qsql 				varchar(255),
	@de2 				varchar(100), 
	@next_test_sql 		varchar(250),
	@alert_id_string 	varchar(20), 
	@email_target 		varchar(100),
	@email_subject 		varchar(100),
	@email_cc 			varchar(100)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ntalert.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "

IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##alertvalues%' AND type = 'U') 
BEGIN
	IF @debug_level >= 3
		SELECT "Dropping ##alertvalues"
	DROP TABLE ##alertvalues
END

IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '#temp_alertvalues%' AND type = 'U') 
BEGIN
	IF @debug_level >= 3
		SELECT "Dropping #temp_alertvalues"
	DROP TABLE #temp_alertvalues
END


SELECT 
	de1		= convert(varchar(100),""), 
	de2		= convert(varchar(100),""), 
	message	= convert(varchar(255),"")
INTO 	##alertvalues
WHERE	0	= 1

SELECT 
	de1		= convert(varchar(100),""), 
	de2		= convert(varchar(100),"")
INTO 	#temp_alertvalues
WHERE	0	= 1


DECLARE alert_master CURSOR FOR 
			SELECT alert_id FROM ntalrtls WHERE next_test < GETDATE()

OPEN alert_master

FETCH 	NEXT 
FROM 	alert_master 
INTO 	@alert_id

WHILE @@fetch_status <> -1
BEGIN
	IF @debug_level >= 3
		SELECT "Start of loop"
		
	SELECT 
		@alert_type		= alert_type, 
		@sql			= sql_text, 
		@sql2			= sql_text2, 
		@sql3			= sql_text3, 
		@sql4			= sql_text4,
		@next_test_sql	= next_test_sql,
		@email_target	= RTRIM(email_target),
		@email_cc		= RTRIM(email_cc),
		@email_subject	= email_subject
	FROM 	ntalrtls
	WHERE 	alert_id	= @alert_id

	EXEC("INSERT ##alertvalues (de1, de2) "+@sql+@sql2+@sql3+@sql4)

	SELECT 	@alert_recs	= COUNT(*) 
	FROM 	##alertvalues

	IF @debug_level >= 3
	BEGIN
		SELECT * 
		FROM ##alertvalues
			
		SELECT alert_recs 	= @alert_recs
	END

	IF @alert_type IN ("S", "R")
		IF @alert_recs > 0
			SELECT @activate	= 1
		ELSE
			SELECT @activate	= 0
	ELSE
	BEGIN
		IF @alert_type="F"
		BEGIN
			IF 	@alert_recs	= (SELECT 	COUNT(*) 
								FROM 	ntalrtvl
								WHERE 	alert_id	= @alert_id)
				AND @alert_recs	= (SELECT 	COUNT(*)
									FROM 	ntalrtvl t, ##alertvalues v
									WHERE 	t.alert_id	= @alert_id
									AND 	t.de1		= v.de1)
				SELECT @activate=0
			ELSE
			BEGIN
				SELECT @activate=1

				INSERT 	#temp_alertvalues
				SELECT 	
						de1, 
						de2
				FROM 	##alertvalues
				WHERE 	de1 not in (SELECT 	de1 
									FROM 	ntalrtvl 
									WHERE 	alert_id	= @alert_id)

				INSERT 	ntalrtvl
				SELECT 	
						@alert_id, 
						de1, 
						de2
				FROM 	#temp_alertvalues

				INSERT 	#temp_alertvalues
				SELECT 	de1, 
						"DROPPED"
				FROM 	ntalrtvl
				WHERE 	alert_id	= @alert_id
				AND 	de1 		NOT IN (SELECT de1 
										FROM ##alertvalues)

				DELETE 	ntalrtvl
				WHERE 	alert_id	= @alert_id
				AND 	de1 		NOT IN (SELECT de1 
											FROM ##alertvalues)

				DELETE ##alertvalues

				INSERT ##alertvalues 
				(
					de1, 
					de2
				)
				SELECT
					 	de1, 
					 	de2 
				FROM 	#temp_alertvalues
			END
		END
		ELSE
		BEGIN
			IF @alert_type="T"
			BEGIN
				IF 		@alert_recs	= (SELECT 	count(*) 
										FROM 	ntalrtvl
										WHERE 	alert_id = @alert_id)
					AND @alert_recs	= (SELECT 	count(*)	
										FROM 	ntalrtvl t, ##alertvalues v
										WHERE 	t.alert_id	= @alert_id
										and 	t.de1		= v.de1
										and 	t.de2		= v.de2)
					SELECT @activate=0
				ELSE
				BEGIN
					SELECT @activate=1
		
					INSERT #temp_alertvalues

					SELECT de1, de2
					FROM 	##alertvalues
					WHERE 	de1 NOT IN (SELECT 	de1 
										FROM 	ntalrtvl 
										WHERE 	alert_id	= @alert_id)
		
					INSERT ntalrtvl
					SELECT 
							@alert_id, 
							de1, 
							de2
					FROM 	#temp_alertvalues
		
					INSERT 	#temp_alertvalues
					SELECT 	de1, 
							"DROPPED"
					FROM 	ntalrtvl
					WHERE 	alert_id	= @alert_id
					AND 	de1 		NOT IN (SELECT de1 
												FROM ##alertvalues)
		
					DELETE 	ntalrtvl
					WHERE 	alert_id	=@alert_id
					AND 	de1 		NOT IN (SELECT de1 
												FROM ##alertvalues)
		
					INSERT 	#temp_alertvalues
					SELECT 	
							v.de1, 
							v.de2
					FROM 	ntalrtvl t, ##alertvalues v
					WHERE 	t.alert_id	= @alert_id
					AND 	t.de1		= v.de1
					AND 	t.de2		<> v.de2
		
					UPDATE 	ntalrtvl
					SET 	de2			= v.de2
					FROM 	ntalrtvl t, ##alertvalues v
					WHERE 	t.alert_id	= @alert_id
					AND 	t.de1		= v.de1
					AND 	t.de2		<> v.de2

					DELETE ##alertvalues

					INSERT ##alertvalues 
					(
						de1, 
						de2
					)
					SELECT 
						de1, 
						de2 
					FROM #temp_alertvalues
				END
			END
			ELSE
				PRINT "error! - Alert type not found!!"
		
		END
	END

	IF @activate=1
	BEGIN
		
		
		UPDATE ##alertvalues
		SET 	message	=	STUFF(
								case when de2="DROPPED" then email_text_out
								else email_text_in
								end,
							CHARINDEX("{1}",
								case when de2="DROPPED" then email_text_out
								else email_text_in
								end),
							3, 
							de1)
		FROM 	##alertvalues v, 
				ntalrtls t
		WHERE 	t.alert_id	= @alert_id
		
		UPDATE 	##alertvalues 
		SET 	message	= stuff(message, charindex("{2}", message), 3, de2)
		WHERE 	de2		<> "DROPPED"
		
		SELECT @qsql	= STR((SELECT MAX(DATALENGTH(RTRIM(message))) FROM ##alertvalues))
		
		SELECT @qsql	= "SELECT SUBSTRING(RTRIM(message),1," + @qsql + ") FROM ##alertvalues"
		
		EXEC master.dbo.xp_startmail
		EXEC master.dbo.xp_sendmail 
				@recipients			= @email_target, 
				@copy_recipients	= @email_cc,
				@subject			= @email_subject,
				@message			= "An alert has been triggered by the following: ",
				@query				= @qsql,
				@no_output			= 'True', 
				@set_user			= 'dbo',
				@width				= 255,
				@no_header			= 'True'
		
		IF @debug_level >= 3
		BEGIN
			SELECT "Sent mail to: " = @email_target,
					"sql stmt: " = @qsql
		END

		IF @alert_type="S"
			DELETE	ntalrtls
			WHERE 	alert_id	= @alert_id
	END

	SELECT @alert_id_string	= str(@alert_id)
	EXEC("UPDATE ntalrtls SET next_test=" + @next_test_sql + " WHERE alert_id = " + @alert_id_string) 
	
	DELETE 	##alertvalues
	DELETE 	#temp_alertvalues
	
	FETCH 	NEXT 
	FROM 	alert_master 
	INTO 	@alert_id
END

CLOSE alert_master

DEALLOCATE alert_master

IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '#temp_alertvalues%' AND type = 'U') 
	DROP TABLE #temp_alertvalues


WAITFOR DELAY "0:00:30"

IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##alertvalues%' AND type = 'U') 
	DROP TABLE ##alertvalues

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ntalert.sp" + ", line " + STR( 370, 5 ) + " -- EXIT: "

GO
GRANT EXECUTE ON  [dbo].[pltntalert_sp] TO [public]
GO
