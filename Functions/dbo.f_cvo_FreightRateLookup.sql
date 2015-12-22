SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Elizabeth LaBarbera
-- Create date: 11/18/2013
-- Description:	Pull carrier rate
-- SELECT dbo.f_cvo_FreightRateLookup('UPSGR','21224','2')
-- =============================================
CREATE FUNCTION [dbo].[f_cvo_FreightRateLookup] 
(
	-- Add the parameters for the function here
@carrier nvarchar(8),
@zip nvarchar(15),
@Wgt nvarchar(15)
)
RETURNS decimal (8,2)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result decimal (8,2)

	-- Add the T-SQL statements to compute the return value here
SET @Result = (select charge  from arshipv S (nolock)
join cvo_carriers C (nolock)ON S.ship_via_code=C.Carrier
join cvo_weights W (nolock) ON W.WEIGHT_CODE=C.WEIGHT_CODE
WHERE SHIP_VIA_CODE like @CARRIER
AND lower_zip <= @zip
and upper_zip >= @zip
and wgt = @Wgt)


	-- Return the result of the function
	RETURN @Result

END
GO
