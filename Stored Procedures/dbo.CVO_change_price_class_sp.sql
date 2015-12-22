SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC [CVO_change_price_class_sp] '12050','G'

CREATE PROCEDURE [dbo].[CVO_change_price_class_sp] @customer VARCHAR(50), @price_code VARCHAR(50) AS
BEGIN
	DECLARE @child		VARCHAR(50),
			@counter	INT,
			@id			INT,
			@tier_level int

	CREATE TABLE #temp(
		id INT IDENTITY(1, 1),
		customer_code VARCHAR(100) NULL
	)

	select @tier_level = tier_level from artierrl where rel_cust = @customer
	If @tier_level > 1
	Begin
		SELECT 1, ' This Change not Allowed.  Customer is a Child of a Parent Customer.'
		RETURN -1
	End


	INSERT INTO #temp (customer_code)
--	SELECT child FROM arnarel WHERE parent = @customer
	select rel_cust from artierrl where parent = @customer

	SELECT @counter = 0

	SELECT @id = MIN(id) FROM #temp
          
	WHILE (@id IS NOT NULL)            
	BEGIN
		SELECT @child = customer_code FROM #temp WHERE id = @id

		UPDATE armaster_all SET price_code = @price_code
		WHERE customer_code = @child AND address_type = 0

		SELECT @counter = @counter + 1

--		EXEC [CVO_change_price_class_sp] @child, @price_code
		
		SELECT @id = MIN(id) FROM #temp WHERE id > @id
	END	

	DROP TABLE #temp

	SELECT @counter
END


GO
GRANT EXECUTE ON  [dbo].[CVO_change_price_class_sp] TO [public]
GO
