SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[f_get_hold_priority](@hold_reason varchar(10),@override varchar(10))
RETURNS int
AS
BEGIN
	-- DECLARATIONS
	DECLARE @priority	int

	IF (@override = 'C&C' AND @hold_reason <> 'PROMOHLD')
	BEGIN
		RETURN 10
	END

	SELECT	@priority = CASE WHEN @hold_reason IN ('CL','PD') THEN 10 -- Credit hold
							 WHEN @hold_reason IN ('STIH') THEN 15 -- v1.1
							 WHEN @hold_reason IN ('FL','SC','RD') THEN 20 -- Inventory level holds		
							 WHEN @hold_reason IN ('GSH') THEN 30 -- Order level holds
							 WHEN @hold_reason IN ('STC','RXC') THEN 50 -- Consolidation level holds
							 WHEN @hold_reason IN ('PROMOHLD') THEN 5 -- Promo level holds
							 ELSE 40 END
	RETURN @priority
END
GO
GRANT REFERENCES ON  [dbo].[f_get_hold_priority] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_get_hold_priority] TO [public]
GO
