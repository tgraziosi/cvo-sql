SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_cust_phone_sp] 
	@workload_code varchar(8),
	@contact_phone varchar(30),
	@direction tinyint = 0

AS
set rowcount 50

IF @workload_code = ''
BEGIN
	If @direction = 0
		SELECT contact_phone 'Contact Phone' ,customer_name 'Customer Name', city 'City', state 'State', postal_code 'Zip', 
		customer_code 'Cust. Code', 2 'Key'
		FROM arcust
		WHERE contact_phone >= @contact_phone
		ORDER BY contact_phone
	If @direction = 1
		SELECT contact_phone 'Contact Phone' ,customer_name 'Customer Name', city 'City', state 'State', postal_code 'Zip', 
		customer_code 'Cust. Code', 2 'Key'
		FROM arcust
		WHERE contact_phone <= @contact_phone
		ORDER BY contact_phone DESC
	If @direction = 2
		SELECT contact_phone 'Contact Phone' ,customer_name 'Customer Name',city 'City', state 'State', postal_code 'Zip', 
		customer_code 'Cust. Code', 2 'Key'
		FROM arcust
		WHERE contact_phone >= @contact_phone
		ORDER BY contact_phone ASC
END

ELSE
BEGIN
	If @direction = 0
		SELECT contact_phone 'Contact Phone' ,customer_name 'Customer Name', city 'City', state 'State', postal_code 'Zip', 
		c.customer_code 'Cust. Code', 2 'Key'
		FROM arcust c, ccwrkmem m
		WHERE contact_phone >= @contact_phone
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY contact_phone
	If @direction = 1
		SELECT contact_phone 'Contact Phone' ,customer_name 'Customer Name', city 'City', state 'State', postal_code 'Zip', 
		c.customer_code 'Cust. Code', 2 'Key'
		FROM arcust c, ccwrkmem m
		WHERE contact_phone <= @contact_phone
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY contact_phone DESC
	If @direction = 2
		SELECT contact_phone 'Contact Phone' ,customer_name 'Customer Name',city 'City', state 'State', postal_code 'Zip', 
		c.customer_code 'Cust. Code', 2 'Key'
		FROM arcust c, ccwrkmem m
		WHERE contact_phone >= @contact_phone
		AND c.customer_code = m.customer_code
		AND workload_code = @workload_code
		ORDER BY contact_phone ASC
END

set rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_cust_phone_sp] TO [public]
GO
