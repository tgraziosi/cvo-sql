SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_workload_code_sp] 
	@workload_code varchar(8),
	@search_type tinyint
AS








IF (@search_type = 1)
	SELECT h.workload_code, workload_desc, workload_clause, type, datatype FROM ccwrkhdr h, ccwrkdet d
		WHERE h.workload_code = @workload_code
		AND h.workload_code = d.workload_code
IF (@search_type = 2)
	SELECT h.workload_code, workload_desc, workload_clause, type, datatype FROM ccwrkhdr h, ccwrkdet d
		WHERE h.workload_code = d.workload_code
		AND h.workload_code = (SELECT min(workload_code) FROM ccwrkhdr)
IF (@search_type = 3)
	SELECT h.workload_code, workload_desc, workload_clause, type, datatype FROM ccwrkhdr h, ccwrkdet d
		WHERE h.workload_code = d.workload_code
		AND h.workload_code = (SELECT max(workload_code) FROM ccwrkhdr)
IF (@search_type = 5)
BEGIN
	SET ROWCOUNT 1
	SELECT h.workload_code, workload_desc, workload_clause, type, datatype FROM ccwrkhdr h, ccwrkdet d
		WHERE h.workload_code > @workload_code
		AND h.workload_code = d.workload_code
		order by h.workload_code ASC
	SET ROWCOUNT 0
END
IF (@search_type = 6)
BEGIN
	SET ROWCOUNT 1
	SELECT h.workload_code, workload_desc, workload_clause, type, datatype FROM ccwrkhdr h, ccwrkdet d
		WHERE h.workload_code < @workload_code
		AND h.workload_code = d.workload_code
		order by h.workload_code DESC
	SET ROWCOUNT 0
ENd
GO
GRANT EXECUTE ON  [dbo].[cc_workload_code_sp] TO [public]
GO
