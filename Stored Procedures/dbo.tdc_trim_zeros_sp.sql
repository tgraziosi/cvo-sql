SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_trim_zeros_sp]
	@decimal_str VARCHAR(255) OUTPUT
AS 

IF CHARINDEX('.', @decimal_str)  > 1  
BEGIN
	WHILE (RIGHT(@decimal_str, 1)  = '0' OR RIGHT(@decimal_str, 1)  = '.')  
	BEGIN
		IF RIGHT(@decimal_str, 1)  = '.' 
		BEGIN 
			SELECT @decimal_str  = SUBSTRING(@decimal_str, 1, LEN(@decimal_str) - 1)  
			BREAK 
		END 
		ELSE
		BEGIN
			SELECT @decimal_str  = SUBSTRING(@decimal_str, 1, LEN(@decimal_str) - 1)
		END
	END
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_trim_zeros_sp] TO [public]
GO
