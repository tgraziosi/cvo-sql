SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION  [dbo].[CVO_get_ResType_PartType_fn]
    (@fn VARCHAR(40))
    
RETURNS VARCHAR(15)

AS
BEGIN
	DECLARE @value_str VARCHAR(15) 

	SET @value_str = 'NONE'
	
	SELECT @value_str = ISNULL(value_str,'NONE')
	FROM   tdc_config (NOLOCK) 
	WHERE  mod_owner = 'GEN' AND 
	      [function] = @fn

    RETURN @value_str
END


GO
GRANT EXECUTE ON  [dbo].[CVO_get_ResType_PartType_fn] TO [public]
GO
