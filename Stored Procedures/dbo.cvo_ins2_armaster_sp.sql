SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[cvo_ins2_armaster_sp]

@customer_code	varchar(16),
@ship_to		varchar(8),
@max_dollars	float,
@metal_plastic	varchar(1),
@suns_opticals	varchar(1)

AS

IF EXISTS (SELECT 1 FROM CVO_armaster_all WHERE customer_code = @customer_code AND ship_to = @ship_to)
BEGIN
	UPDATE CVO_armaster_all
	SET max_dollars = @max_dollars, metal_plastic = @metal_plastic, suns_opticals = @suns_opticals 
	WHERE customer_code = @customer_code AND ship_to = @ship_to
END
ELSE
BEGIN
	INSERT INTO CVO_armaster_all (customer_code,ship_to,address_type,coop_eligible,max_dollars,metal_plastic,suns_opticals,cvo_print_cm,cvo_chargebacks)
	VALUES(@customer_code,@ship_to,1,null,@max_dollars,@metal_plastic,@suns_opticals,'','')
END


GO
GRANT EXECUTE ON  [dbo].[cvo_ins2_armaster_sp] TO [public]
GO
