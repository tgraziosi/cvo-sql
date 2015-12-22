SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 15/01/2014 - Issue #1413 - return freight type for order
-- v1.1 CT 12/02/2014 - Issue #1450 - Get account number from cust_carrier_account
-- EXEC cvo_return_freight_type_sp 1420047,0
CREATE PROC [dbo].[cvo_return_freight_type_sp]	@order_no INT,
											@ext INT
AS
BEGIN

	SET NOCOUNT ON


	DECLARE @sold_to		VARCHAR(8),
			@carrier		VARCHAR(20),
			@lab_carrier	VARCHAR(8),
			@lab_account	VARCHAR(40),
			@freight_type	VARCHAR(10)

	-- Get order details
	SELECT 
		@sold_to = sold_to,
		@carrier = routing,
		@freight_type = freight_allow_type
	FROM 
		dbo.orders_all (NOLOCK) 
	WHERE 
		order_no = @order_no 
		AND ext = @ext

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT ''
		RETURN
	END

	-- 3rd party freight no global lab
	IF LEFT(@carrier,1) = '3'AND ISNULL(@sold_to,'') = ''
	BEGIN
		SELECT 'COLLECT'
		RETURN
	END

	-- 3rd party freight with global lab and blank freight type
	IF LEFT(@carrier,1) = '3'AND ISNULL(@sold_to,'') <> '' AND ISNULL(@freight_type,'') = ''
	BEGIN
		-- START v1.1
		SELECT  
			@lab_carrier = routing,  
			@lab_account = account  
		FROM  
			dbo.cust_carrier_account (NOLOCK)
		WHERE   
			cust_code = @sold_to   
			AND freight_allow_type = 'THRDPRTY'  
			AND routing = @carrier 
		/*
		-- Get global lab details
		SELECT
			@lab_carrier = ship_via_code,
			@lab_account = addr_sort1
		FROM
			dbo.armaster_all (NOLOCK)
		WHERE
			customer_code = @sold_to 
			AND address_type = 9 
		*/
		-- END v1.1

		-- Has account number
		IF ISNULL(@lab_account,'') <> ''
		BEGIN
			-- START v1.1
			/*
			-- Order and global lab's carrier's are the same
			IF @carrier = @lab_carrier
			BEGIN
				SELECT 'THRDPRTY'
				RETURN
			END
			ELSE
			BEGIN
				SELECT 'COLLECT'
				RETURN
			END
			*/
			SELECT 'THRDPRTY'
			RETURN
			-- END v1.1
		END
		ELSE
		BEGIN
			-- No account
			SELECT 'COLLECT'
			RETURN
		END
	END

	SELECT ''
	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[cvo_return_freight_type_sp] TO [public]
GO
