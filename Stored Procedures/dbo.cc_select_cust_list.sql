SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_select_cust_list] @workload_code	varchar(8),
				 @override_flag	smallint = 0

AS

SET QUOTED_IDENTIFIER OFF
SET NOCOUNT ON
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

IF ((SELECT datediff(dd, update_date, getdate()) FROM ccwrkhdr
		WHERE workload_code = @workload_code) > 1 ) or @override_flag = 1

	BEGIN
		SELECT @type = ISNULL( MAX(type),0 ) FROM ccwrkdet
			WHERE workload_code = @workload_code
			AND type IS NOT NULL
	
		IF @type = 0
			BEGIN
				SELECT @clause1 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 1
					AND workload_code = @workload_code), "")
				SELECT @clause2 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 2
					AND workload_code = @workload_code), "")
				SELECT @clause3 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 3
					AND workload_code = @workload_code), "")
				SELECT @clause4 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 4
					AND workload_code = @workload_code), "")
				SELECT @clause5 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 5
					AND workload_code = @workload_code), "")
				SELECT @clause6 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 6
					AND workload_code = @workload_code), "")
				SELECT @clause7 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 7
					AND workload_code = @workload_code), "")
				SELECT @clause8 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 8
					AND workload_code = @workload_code), "")
				SELECT @clause9 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 9
					AND workload_code = @workload_code), "")
				SELECT @clause10 = isnull((SELECT " AND " + workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 10
					AND workload_code = @workload_code), "")
			
				SELECT @having_clause = isnull((SELECT workload_clause
					FROM ccwrkdet
					WHERE sequence_id = 11
					AND workload_code = @workload_code), "")
			
				DELETE FROM ccwrkmem
					WHERE workload_code = @workload_code
			


				EXEC ("INSERT ccwrkmem 
					SELECT DISTINCT '" + @workload_code + "', m.customer_code FROM armaster m, aractcus a"
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
				
					IF @@error <> 0
						RETURN
			END
	

	IF @type = 1
		BEGIN
			DELETE FROM ccwrkmem
				WHERE workload_code = @workload_code
	
			SELECT @viewname = workload_clause FROM ccwrkdet
				WHERE type = 1
				AND workload_code = @workload_code
	
			EXEC ("INSERT ccwrkmem 
				SELECT DISTINCT '" + @workload_code + "', customer_code FROM " + @viewname)
		
			IF @@error <> 0
				RETURN
	
		END

	IF @type = 2
		BEGIN
			DELETE FROM ccwrkmem
				WHERE workload_code = @workload_code
	
			SELECT @viewname = workload_clause FROM ccwrkdet
				WHERE type = 2
				AND workload_code = @workload_code
	
			EXEC ("INSERT ccwrkmem 
				SELECT DISTINCT '" + @workload_code + "', customer_code FROM arcust " + @viewname)
		
			IF @@error <> 0
				RETURN
	
		END

	UPDATE ccwrkhdr set update_date = getdate()
		WHERE workload_code = @workload_code

END

SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_select_cust_list] TO [public]
GO
