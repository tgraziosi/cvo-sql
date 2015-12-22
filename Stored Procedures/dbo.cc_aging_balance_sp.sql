SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_aging_balance_sp] 
	@customer_code		varchar(8),	
	@date_type_parm		varchar(2) 	= "3",					 
	@balance 		float 		= NULL OUTPUT	
AS
	BEGIN

		SET QUOTED_IDENTIFIER OFF

		SELECT 	@balance = SUM(amount)
		FROM 	artrxage
		WHERE customer_code = @customer_code
			
			
END 
GO
GRANT EXECUTE ON  [dbo].[cc_aging_balance_sp] TO [public]
GO
