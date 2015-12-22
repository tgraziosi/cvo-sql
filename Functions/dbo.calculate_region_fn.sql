SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Kevin>
-- Create date: <Sept 11 2012, ,>
-- Description:	<To Get the Region based on territory>
-- =============================================
CREATE FUNCTION [dbo].[calculate_region_fn] (@Territory varchar(8))
RETURNS varchar(3)
AS
BEGIN
	
	DECLARE @Region varchar(3)
	DECLARE	@temp varchar(3)
	
	
	SET @temp = Left(@Territory,2)

	IF @temp <> '90'
	   set @Region = @temp + '0'
    Else IF  @temp = '90' AND Right(Left(@Territory,3),1) = '6'
       set @Region =  Right(Left(@Territory,3),1) + '00'
    Else 
       set @Region = @temp + '0'    
   	
	RETURN @Region

END

GO
