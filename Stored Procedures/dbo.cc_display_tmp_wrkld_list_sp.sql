SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_display_tmp_wrkld_list_sp]
		@workload_code varchar(8)
AS
	DECLARE @clause1 varchar(255)
	DECLARE @clause2 varchar(255)
	DECLARE @clause3 varchar(255)
	DECLARE @clause4 varchar(255)
	DECLARE @clause5 varchar(255)
	DECLARE @clause6 varchar(255)
	DECLARE @clause7 varchar(255)
	DECLARE @clause8 varchar(255)
	DECLARE @clause9 varchar(255)
	DECLARE @clause10 varchar(255)
	DECLARE @having_clause varchar(255)
	DECLARE @type 	tinyint
	DECLARE @viewname	varchar(255)
	DECLARE @custom_where varchar(255)

SELECT @type = MAX(type) FROM #ccwrkdet_temp
	WHERE workload_code = @workload_code

CREATE TABLE ##temp_load (customer_code varchar(8))

IF @type = 0
	BEGIN
		SELECT @clause1 = isnull((SELECT " AND  " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 1), "")
		SELECT @clause2 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 2), "")
		SELECT @clause3 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 3), "")
		SELECT @clause4 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 4), "")
		SELECT @clause5 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 5), "")
		SELECT @clause6 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 6), "")
		SELECT @clause7 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 7), "")
		SELECT @clause8 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 8), "")
		SELECT @clause9 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 9), "")
		SELECT @clause10 = isnull((SELECT " AND " + workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 10), "")
		SELECT @having_clause = isnull((SELECT workload_clause
			FROM #ccwrkdet_temp
			WHERE sequence_id = 11
			AND workload_code = @workload_code), "")
	
		
	
		EXEC ("INSERT ##temp_load 
			SELECT DISTINCT m.customer_code FROM armaster m, aractcus a" 

	


			+ " WHERE m.customer_code = a.customer_code " + @clause1
			+ @clause2
			+ @clause3
			+ @clause4
			+ @clause5
			+ @clause6
			+ @clause7
			+ @clause8
			+ @clause9
			+ @clause10

			+ " AND m.address_type = 0	"
			+ " GROUP BY m.customer_code "
			+ @having_clause)

		SELECT * from arcust c, ##temp_load l
		WHERE c.customer_code = l.customer_code
	END

IF @type = 1
	BEGIN
		SELECT @viewname = workload_clause FROM #ccwrkdet_temp
			WHERE type = 1
			AND workload_code = @workload_code

		If @viewname IS NOT NULL
			EXEC ("INSERT ##temp_load 
				SELECT DISTINCT customer_code FROM " + @viewname)

				SELECT * from arcust c, ##temp_load l
				WHERE c.customer_code = l.customer_code
	
		IF @@error <> 0
			RETURN

	END
	
IF @type = 2
	BEGIN
		SELECT @custom_where = workload_clause FROM #ccwrkdet_temp
		WHERE type = 2
		AND workload_code = @workload_code
		

		IF ( SELECT CHARINDEX('DELETE', UPPER(@custom_where )) + 
								CHARINDEX('UPDATE', UPPER(@custom_where )) + 
								CHARINDEX('EXEC', UPPER(@custom_where )) + 
								CHARINDEX('CREATE', UPPER(@custom_where )) + 
								CHARINDEX('INSERT', UPPER(@custom_where )) + 
								CHARINDEX('TRUNCATE', UPPER(@custom_where )) + 
								CHARINDEX('DROP', UPPER(@custom_where )) + 
								CHARINDEX('ALTER', UPPER(@custom_where ))) > 0
			RETURN 

		IF UPPER(SUBSTRING(LTRIM(RTRIM(@custom_where)), 1, 5 )) = 'WHERE'
			BEGIN
				EXEC ( 'SELECT customer_code, customer_name FROM arcust ' + @custom_where )
			
				IF @@error <> 0
					RETURN
			END



	END

 
DROP TABLE ##temp_load
DROP TABLE #ccwrkdet_temp
GO
GRANT EXECUTE ON  [dbo].[cc_display_tmp_wrkld_list_sp] TO [public]
GO
