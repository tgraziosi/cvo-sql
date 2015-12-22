SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cc_state_zoom_sp]
	@workload_code varchar(8) = '',
	@state varchar(40) = '',
	@direction tinyint = 0

AS

CREATE TABLE #results( customer_code varchar(8), customer_name varchar(40), city varchar(40), state varchar(40), postal_code varchar(15), contact_phone varchar(30) )

set rowcount 50
SELECT @state = REPLACE(@state, '%', '' )

IF @workload_code = ''
BEGIN
	IF @direction = 0
		SELECT state "State", city "City", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM arcust
		WHERE state >= @state
		ORDER BY state
	IF @direction = 1
		INSERT #results
		SELECT customer_code,customer_name, city, state, postal_code, contact_phone
		FROM arcust
		WHERE state <= @state
		ORDER BY state DESC

		SELECT state "State", city "City", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM #results
		ORDER BY state ASC
	IF @direction = 2
		SELECT state "State", city "City", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM arcust
		WHERE state >= @state
		ORDER BY state ASC
END

ELSE
BEGIN
	IF @direction = 0
		SELECT state "State", city "City", postal_code "Zip", c.customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM arcust c, ccwrkmem m
		WHERE c.state >= @state
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.state
	IF @direction = 1
		INSERT #results
		SELECT c.customer_code,customer_name, city, state, postal_code,contact_phone
		FROM arcust c, ccwrkmem m
		WHERE c.state <= @state
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.state DESC

		SELECT state "State", city "City", postal_code "Zip", customer_code "Cust. Code", customer_name "Customer Name", contact_phone "Phone"
		FROM #results
		ORDER BY state ASC

	IF @direction = 2
		SELECT postal_code "Zip", c.customer_code "Cust. Code",customer_name "Customer Name", city "City", state "State", contact_phone "Phone"
		FROM arcust c, ccwrkmem m
		WHERE c.state >= @state
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.state ASC
END

SET rowcount 0
DROP TABLE #results

GO
GRANT EXECUTE ON  [dbo].[cc_state_zoom_sp] TO [public]
GO
