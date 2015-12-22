SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_na_acct_sp]
	@workload_code varchar(8) = '',
	@parent varchar(8),
	@direction tinyint = 0

AS
	SET rowcount 50
	IF @workload_code = ''
		BEGIN
			IF @direction = 0
				SELECT parent 'Parent', child_1 'Child 1'
				FROM artierrl
				WHERE parent >= @parent
				ORDER BY parent
			IF @direction = 1
				SELECT parent 'Parent', child_1 'Child 1'
				FROM artierrl
				WHERE parent < @parent
				ORDER BY parent DESC
			IF @direction = 2
				SELECT parent 'Parent', child_1 'Child 1'
				FROM artierrl
				WHERE parent > @parent
				ORDER BY parent
		END

	ELSE
		BEGIN
			IF @direction = 0
				SELECT DISTINCT t.parent 'Parent', child_1 'Child 1 '
				FROM artierrl t, ccwrkmem m
				WHERE t.parent >= @parent
				AND t.parent = m.customer_code
				AND workload_code = @workload_code
				ORDER BY t.parent
			IF @direction = 1
				SELECT DISTINCT t.parent 'Parent',child_1 'Child 1 '
				FROM artierrl t, ccwrkmem m
				WHERE t.parent <= @parent
				AND t.parent = m.customer_code
				AND workload_code = @workload_code
				ORDER BY t.parent DESC
			IF @direction = 2
				SELECT DISTINCT t.parent 'Parent',child_1 'Child 1 '
				FROM artierrl t, ccwrkmem m
				WHERE t.parent >= @parent
				AND t.parent = m.customer_code
				AND workload_code = @workload_code
				ORDER BY t.parent ASC
		END

	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_na_acct_sp] TO [public]
GO
