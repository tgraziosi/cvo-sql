SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_cust_name_sp]
	@workload_code varchar(8) = "",
	@cust_name varchar(41),
	@direction tinyint = 0,
	@last_value varchar(41) = NULL

AS

CREATE TABLE #results( customer_code varchar(8), customer_name varchar(40), city varchar(40) NULL, state varchar(40) NULL, postal_code varchar(15) NULL, contact_phone varchar(30) NULL )


set rowcount 50


DECLARE @like_name varchar(41)
IF (select CHARINDEX('%',@cust_name,0)) > 0
	GOTO DO_LIKE

IF @workload_code = ""
BEGIN
	IF @direction = 0
		SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust
		WHERE customer_name >= @cust_name
		ORDER BY customer_name
	IF @direction = 1
		BEGIN
			INSERT #results
			SELECT customer_name, customer_code, city, state, postal_code
			FROM arcust
			WHERE customer_name <= @cust_name
			ORDER BY customer_name DESC
	
			SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
			FROM #results
			ORDER BY customer_name ASC
		END
	IF @direction = 2
		SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust
		WHERE customer_name >= @cust_name
		ORDER BY customer_name ASC
END

ELSE
BEGIN
	IF @direction = 0
		SELECT c.customer_name "Customer Name", c.customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust c, ccwrkmem m
		WHERE c.customer_name >= @cust_name
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.customer_name
	IF @direction = 1
		BEGIN
			INSERT #results
			SELECT customer_name, c.customer_code, city, state, postal_code
			FROM arcust c, ccwrkmem m
			WHERE c.customer_name <= @cust_name
			AND c.customer_code = m.customer_code
			AND workload_code = @workload_code
			ORDER BY c.customer_name DESC
	
			SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
			FROM #results
			ORDER BY customer_name ASC
		END
	IF @direction = 2
		SELECT c.customer_name "Customer Name", c.customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust c, ccwrkmem m
		WHERE c.customer_name >= @cust_name
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.customer_name ASC

END
GOTO EXIT_PROC
DO_LIKE:
IF @workload_code = ""
BEGIN
	IF @direction = 0
		SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust
		WHERE customer_name LIKE @cust_name
		ORDER BY customer_name
	IF @direction = 1
		BEGIN
			INSERT #results
			SELECT customer_name, customer_code, city, state, postal_code
			FROM arcust
			WHERE customer_name LIKE @cust_name
			and customer_name <= @last_value
			ORDER BY customer_name DESC
	
			SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
			FROM #results
			ORDER BY customer_name ASC
		END
	IF @direction = 2
		SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust
		WHERE customer_name LIKE @cust_name
		and customer_name >= @last_value
		ORDER BY customer_name ASC
END

ELSE
BEGIN
	IF @direction = 0
		SELECT c.customer_name "Customer Name", c.customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust c, ccwrkmem m
		WHERE c.customer_name LIKE @cust_name
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.customer_name
	IF @direction = 1
		BEGIN
			INSERT #results
			SELECT customer_name, c.customer_code, city, state, postal_code
			FROM arcust c, ccwrkmem m
			WHERE c.customer_name LIKE @cust_name
			and c.customer_name <= @last_value
			AND c.customer_code = m.customer_code
			AND workload_code = @workload_code
			ORDER BY c.customer_name DESC
	
			SELECT customer_name "Customer Name", customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
			FROM #results
			ORDER BY customer_name ASC
		END
	IF @direction = 2
		SELECT c.customer_name "Customer Name", c.customer_code "Cust. Code", city "City", state "State", postal_code "Zip", 1 "Key"
		FROM arcust c, ccwrkmem m
		WHERE c.customer_name LIKE @cust_name
		and c.customer_name >= @last_value
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY c.customer_name ASC

END
EXIT_PROC:
SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_cust_name_sp] TO [public]
GO
