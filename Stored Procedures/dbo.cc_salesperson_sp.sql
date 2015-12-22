SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_salesperson_sp]
	@workload_code varchar(8) = '',
	@salesperson_code varchar(8),
	@direction tinyint = 0

AS
	SET rowcount 50
	IF @workload_code = ''
		BEGIN
			IF @direction = 0
				SELECT salesperson_code 'Sales Code', salesperson_name 'Salesperson Name'
				FROM arsalesp
				WHERE salesperson_code >= @salesperson_code
				ORDER BY salesperson_code
			IF @direction = 1
				SELECT salesperson_code 'Sales Code', salesperson_name 'Salesperson Name'
				FROM arsalesp
				WHERE salesperson_code < @salesperson_code
				ORDER BY salesperson_code DESC
			IF @direction = 2
				SELECT salesperson_code 'Sales Code', salesperson_name 'Salesperson Name'
				FROM arsalesp
				WHERE salesperson_code > @salesperson_code
				ORDER BY salesperson_code
		END

	ELSE
		BEGIN
			IF @direction = 0
				SELECT DISTINCT t.salesperson_code 'Sales Code', salesperson_name 'Salesperson Name '
				FROM arsalesp t, arcust a, ccwrkmem m
				WHERE t.salesperson_code >= @salesperson_code
				AND a.customer_code = m.customer_code
				AND a.salesperson_code = t.salesperson_code
				AND workload_code = @workload_code
				ORDER BY t.salesperson_code
			IF @direction = 1
				SELECT DISTINCT t.salesperson_code 'Sales Code',salesperson_name 'Salesperson Name '
				FROM arsalesp t, arcust a, ccwrkmem m
				WHERE t.salesperson_code <= @salesperson_code
				AND a.customer_code = m.customer_code
				AND a.salesperson_code = t.salesperson_code
				AND workload_code = @workload_code
				ORDER BY t.salesperson_code DESC
			IF @direction = 2
				SELECT DISTINCT t.salesperson_code 'Sales Code',salesperson_name 'Salesperson Name '
				FROM arsalesp t, arcust a, ccwrkmem m
				WHERE t.salesperson_code >= @salesperson_code
				AND a.customer_code = m.customer_code
				AND a.salesperson_code = t.salesperson_code
				AND workload_code = @workload_code
				ORDER BY t.salesperson_code ASC
		END

	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_salesperson_sp] TO [public]
GO
