SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                















CREATE FUNCTION [dbo].[CCAMask_fn] (@acc VARCHAR(20))
    RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @accmasked VARCHAR (20)
	SELECT @acc = RTRIM(LTRIM(@acc))
	IF LEN(@acc) > 6
		SELECT @accmasked =  LEFT(@acc ,2)+ REPLICATE ( '*' , LEN(@acc)-6 ) +  RIGHT(@acc ,4)
	ELSE	
		SELECT @accmasked =''
	RETURN @accmasked
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[CCAMask_fn] TO [public]
GO
