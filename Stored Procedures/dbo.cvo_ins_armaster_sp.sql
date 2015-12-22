SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CB 29/05/2012 - default freight_charge
-- v1.2 CT 11/10/2012 - default credit_for_returns
-- v1.3 CB 27/11/2012 - Issue #928 - Add cases default to YES
-- v1.4 CB 12/02/2014 - Issue #1334 - Default door to 1
CREATE PROCEDURE  [dbo].[cvo_ins_armaster_sp]

@customer_code	varchar(16),
@max_dollars	float,
@metal_plastic	varchar(1),
@suns_opticals	varchar(1),
@print_cm		varchar(1),
@chgebck		varchar(1)

AS

IF EXISTS (SELECT 1 FROM CVO_armaster_all WHERE customer_code=@customer_code)
BEGIN
	UPDATE CVO_armaster_all
	SET max_dollars = @max_dollars, metal_plastic = @metal_plastic, suns_opticals = @suns_opticals, 
		cvo_print_cm = @print_cm, cvo_chargebacks = @chgebck 
	WHERE customer_code = @customer_code
END
ELSE
BEGIN
	INSERT INTO CVO_armaster_all (customer_code,ship_to,coop_eligible,max_dollars,metal_plastic,suns_opticals,cvo_print_cm,cvo_chargebacks,freight_charge,credit_for_returns,add_cases, door) -- v1.1 + v1.2 + v1.3 + v1.4
	VALUES(@customer_code,' ','Y',@max_dollars,@metal_plastic,@suns_opticals,@print_cm,@chgebck,1,0, 'Y', 1)-- v1.1 + v1.2 + v1.3 + v1.4

	IF NOT EXISTS (SELECT 1 FROM glref WHERE reference_type = 'COOP' and reference_code = @customer_code)
	BEGIN
		INSERT INTO glref SELECT Null, @customer_code, customer_name, 'COOP', 0 FROM arcust WHERE customer_code = @customer_code
	END
END



GO
GRANT EXECUTE ON  [dbo].[cvo_ins_armaster_sp] TO [public]
GO
