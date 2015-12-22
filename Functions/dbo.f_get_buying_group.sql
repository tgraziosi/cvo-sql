SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT dbo.f_get_buying_group('000620')
-- v1.0 CT 13/07/2012 - Returns buying group for customer passed in
-- v1.1 CT 11/10/2012 - Add address_type = 0 

CREATE FUNCTION [dbo].[f_get_buying_group] (@cust_code VARCHAR(10))
RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @BuyingGroup VARCHAR(10)

	SELECT TOP 1
		@BuyingGroup = a.parent
	FROM 
		dbo.artierrl a (NOLOCK)
	INNER JOIN 
		dbo.armaster_all b (NOLOCK)
	ON 
		a.parent = b.customer_code
	WHERE 
		a.tier_level = 2
		AND b.addr_sort1 = 'buying group' 
		AND a.rel_cust = @cust_code
		AND b.address_type = 0 

	RETURN ISNULL(@BuyingGroup,'')

END
GO
GRANT REFERENCES ON  [dbo].[f_get_buying_group] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_get_buying_group] TO [public]
GO
