SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_wrkdet_insert_temp_sp]
	@workload_code varchar(8),
	@workload_clause varchar(255),
	@having tinyint = 0,
	@type	tinyint = 0
AS
IF @having = 0
	INSERT #ccwrkdet_temp 
		SELECT @workload_code,@workload_clause, ISNULL((SELECT max(sequence_id) + 1 
								FROM #ccwrkdet_temp 
								WHERE workload_code = @workload_code), 1), @type
ELSE
	INSERT #ccwrkdet_temp 
		SELECT @workload_code,@workload_clause, 11, @type 
GO
GRANT EXECUTE ON  [dbo].[cc_wrkdet_insert_temp_sp] TO [public]
GO
