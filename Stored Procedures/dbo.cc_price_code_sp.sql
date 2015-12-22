SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_price_code_sp]
	@workload_code varchar(8) = '',
	@price_code varchar(8),
	@direction tinyint = 0

AS
	SET rowcount 50
	IF @workload_code = ''
		BEGIN
			IF @direction = 0
				SELECT price_code 'Price Code', description 'Description'
				FROM arprice
				WHERE price_code >= @price_code
				ORDER BY price_code
			IF @direction = 1
				SELECT price_code 'Price Code', description 'Description'
				FROM arprice
				WHERE price_code < @price_code
				ORDER BY price_code DESC
			IF @direction = 2
				SELECT price_code 'Price Code', description 'Description'
				FROM arprice
				WHERE price_code > @price_code
				ORDER BY price_code
		END

	ELSE
		BEGIN
			IF @direction = 0
				SELECT DISTINCT t.price_code 'Price Code', description 'Description '
				FROM arprice t, arcust a, ccwrkmem m
				WHERE t.price_code >= @price_code
				AND a.customer_code = m.customer_code
				AND a.price_code = t.price_code
				AND workload_code = @workload_code
				ORDER BY t.price_code
			IF @direction = 1
				SELECT DISTINCT t.price_code 'Price Code',description 'Description '
				FROM arprice t, arcust a, ccwrkmem m
				WHERE t.price_code <= @price_code
				AND a.customer_code = m.customer_code
				AND a.price_code = t.price_code
				AND workload_code = @workload_code
				ORDER BY t.price_code DESC
			IF @direction = 2
				SELECT DISTINCT t.price_code 'Price Code',description 'Description '
				FROM arprice t, arcust a, ccwrkmem m
				WHERE t.price_code >= @price_code
				AND a.customer_code = m.customer_code
				AND a.price_code = t.price_code
				AND workload_code = @workload_code
				ORDER BY t.price_code ASC
		END

	SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_price_code_sp] TO [public]
GO
