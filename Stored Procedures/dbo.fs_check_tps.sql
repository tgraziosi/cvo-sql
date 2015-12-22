SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[fs_check_tps] 
AS  

SELECT 	int_value, 
	char_value
FROM 	CVO_Control..dminfo
WHERE 	property_id	= 53000 

GO
GRANT EXECUTE ON  [dbo].[fs_check_tps] TO [public]
GO
