SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_apply_to_num_sp]
	@workload_code varchar(8) = '',
	@apply_to_num varchar(16),
	@direction tinyint = 0

AS
	SET rowcount 50
	IF @workload_code = ''
		BEGIN
			IF @direction = 0
				SELECT DISTINCT apply_to_num 'Apply To Number', payer_cust_code 'Customer'
				FROM artrxage
				WHERE apply_to_num >= @apply_to_num
				ORDER BY apply_to_num
			IF @direction = 1
				SELECT DISTINCT apply_to_num 'Apply To Number', payer_cust_code 'Customer'
				FROM artrxage
				WHERE apply_to_num < @apply_to_num
				ORDER BY apply_to_num DESC
			IF @direction = 2
				SELECT DISTINCT apply_to_num 'Apply To Number', payer_cust_code 'Customer'
				FROM artrxage
				WHERE apply_to_num > @apply_to_num
				ORDER BY apply_to_num
		END

	ELSE
		BEGIN
			IF @direction = 0
				SELECT DISTINCT t.apply_to_num 'Apply To Number', payer_cust_code 'Customer '
				FROM artrxage t, arcust a, ccwrkmem m
				WHERE t.apply_to_num >= @apply_to_num
				AND a.customer_code = m.customer_code
				AND a.customer_code = t.payer_cust_code
				AND workload_code = @workload_code
				ORDER BY t.apply_to_num
			IF @direction = 1
				SELECT DISTINCT t.apply_to_num 'Apply To Number',payer_cust_code 'Customer '
				FROM artrxage t, arcust a, ccwrkmem m
				WHERE t.apply_to_num <= @apply_to_num
				AND a.customer_code = m.customer_code
				AND a.customer_code = t.payer_cust_code
				AND workload_code = @workload_code
				ORDER BY t.apply_to_num DESC
			IF @direction = 2
				SELECT DISTINCT t.apply_to_num 'Apply To Number',payer_cust_code 'Customer '
				FROM artrxage t, arcust a, ccwrkmem m
				WHERE t.apply_to_num >= @apply_to_num
				AND a.customer_code = m.customer_code
				AND a.customer_code = t.payer_cust_code
				AND workload_code = @workload_code
				ORDER BY t.apply_to_num ASC
		END

	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_apply_to_num_sp] TO [public]
GO
