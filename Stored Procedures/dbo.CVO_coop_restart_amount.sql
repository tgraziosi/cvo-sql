SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			CVO_coop_restart_amount		
Project ID:		Issue 721
Type:			Stored Procedure
Description:	Resets Coop values for all customers

History
-------
v1.1	05/07/12	CT	Add coop_ytd column
v1.2	25/02/13	CT	Coop values no longer updated within Enterprise

*/
          
CREATE PROCEDURE [dbo].[CVO_coop_restart_amount]
AS            
BEGIN
	DECLARE @customer_code VARCHAR(100)

	-- START v1.2
	RETURN
	-- END v1.2

	DECLARE c_CVO_armaster_all CURSOR LOCAL FOR
	SELECT customer_code
	FROM CVO_armaster_all
	ORDER BY customer_code

	OPEN c_CVO_armaster_all
	FETCH NEXT FROM c_CVO_armaster_all INTO	@customer_code

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE 
			CVO_armaster_all 
		SET 
			coop_dollars_previous = coop_dollars, 
			coop_dollars = 0, 
			coop_redeemed = 0,
			coop_ytd = 0		-- v1.1
		WHERE 
			customer_code = @customer_code 
			AND address_type = 0
		
		FETCH NEXT FROM c_CVO_armaster_all INTO	@customer_code
	END
	
	CLOSE c_CVO_armaster_all
	DEALLOCATE c_CVO_armaster_all
	
	SELECT 1
END

GO
GRANT EXECUTE ON  [dbo].[CVO_coop_restart_amount] TO [public]
GO
