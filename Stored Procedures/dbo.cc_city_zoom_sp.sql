SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cc_city_zoom_sp]
	@workload_code varchar(8) = "",
	@city varchar(40) = "",
	@direction tinyint = 0

AS

CREATE TABLE #results( customer_code varchar(8), customer_name varchar(40), city varchar(40) NULL, state varchar(40) NULL, postal_code varchar(15) NULL, contact_phone varchar(30) NULL )

set rowcount 50
SELECT @city = REPLACE(@city, '%', '' )

IF @workload_code = ""
BEGIN
	IF @direction = 0
		SELECT city "City", state "State", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM arcust
		WHERE city >= @city
		ORDER BY city
	IF @direction = 1
		INSERT #results
		SELECT customer_code,customer_name, city, state, postal_code, contact_phone
		FROM arcust
		WHERE city <= @city
		ORDER BY city DESC

		SELECT city "City", state "State", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM #results
		ORDER BY city ASC
	IF @direction = 2
		SELECT city "City", state "State", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM arcust
		WHERE city >= @city
		ORDER BY city ASC
END

ELSE
BEGIN
	IF @direction = 0
		SELECT postal_code "Zip", c.customer_code "Cust. Code", c.customer_name "Customer Name", city "City", state "State", contact_phone "Phone"
		FROM arcust c, ccwrkmem m
		WHERE c.city >= @city
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.city
	IF @direction = 1
		INSERT #results
		SELECT c.customer_code,customer_name, city, state, postal_code,contact_phone
		FROM arcust c, ccwrkmem m
		WHERE c.city <= @city
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.city DESC

		SELECT city "City", state "State", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM #results
		ORDER BY city ASC

	IF @direction = 2
		SELECT postal_code "Zip", c.customer_code "Cust. Code",customer_name "Customer Name", city "City", state "State", contact_phone "Phone"
		FROM arcust c, ccwrkmem m
		WHERE c.city >= @city
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.city ASC
END

SET rowcount 0
DROP TABLE #results

GO
GRANT EXECUTE ON  [dbo].[cc_city_zoom_sp] TO [public]
GO
