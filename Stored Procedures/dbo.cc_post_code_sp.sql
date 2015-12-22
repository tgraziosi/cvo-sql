SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_post_code_sp]
	@workload_code varchar(8) = "",
	@post_code varchar(9) = "",
	@direction tinyint = 0
	
	

AS
set rowcount 50

IF @workload_code = ""
BEGIN
	IF @direction = 0
		SELECT posting_code "Post. Code", description "Description "
		FROM araccts
		WHERE posting_code >= @post_code
		ORDER BY posting_code
	IF @direction = 1
		SELECT posting_code "Post. Code",description "Description "
		FROM araccts
		WHERE posting_code <= @post_code
		ORDER BY posting_code DESC
	IF @direction = 2
		SELECT posting_code "Post. Code",description "Description "
		FROM araccts
		WHERE posting_code >= @post_code
		ORDER BY posting_code ASC
END

ELSE
BEGIN
	IF @direction = 0
		SELECT DISTINCT c.posting_code "Post. Code", description "Description "
		FROM araccts c, arcust a, ccwrkmem m
		WHERE c.posting_code >= @post_code
		AND a.customer_code = m.customer_code
		AND a.posting_code = c.posting_code
		AND workload_code = @workload_code
		ORDER BY c.posting_code
	IF @direction = 1
		SELECT DISTINCT c.posting_code "Post. Code",description "Description "
		FROM araccts c, arcust a, ccwrkmem m
		WHERE c.posting_code <= @post_code
		AND a.customer_code = m.customer_code
		AND a.posting_code = c.posting_code
		AND workload_code = @workload_code
		ORDER BY c.posting_code DESC
	IF @direction = 2
		SELECT DISTINCT c.posting_code "Post. Code",description "Description "
		FROM araccts c, arcust a, ccwrkmem m
		WHERE c.posting_code >= @post_code
		AND a.customer_code = m.customer_code
		AND a.posting_code = c.posting_code
		AND workload_code = @workload_code
		ORDER BY c.posting_code ASC
END

SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_post_code_sp] TO [public]
GO
