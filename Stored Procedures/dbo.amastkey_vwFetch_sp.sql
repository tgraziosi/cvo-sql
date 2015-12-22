SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastkey_vwFetch_sp] 
( 
	@rowsrequested		smallint 	= 1,
	@co_asset_id		smSurrogateKey 
) 
AS 

CREATE TABLE #temp 
( 
	timestamp 					varbinary(8) 	null,
	co_asset_id 				int 			null,
	asset_ctrl_num 				char(16) 		null,
	asset_description 			varchar(40) 	null
)

DECLARE 
	@rowsfound 			smallint, 
	@MSKco_asset_id 	smSurrogateKey

SELECT @rowsfound = 0 
SELECT @MSKco_asset_id = @co_asset_id 

IF EXISTS (SELECT 	co_asset_id 
			FROM 	amasset 
			WHERE 	co_asset_id	= @MSKco_asset_id )
BEGIN 
	WHILE @MSKco_asset_id IS NOT NULL AND @rowsfound < @rowsrequested 
	BEGIN 

		INSERT 	INTO #temp 
		SELECT 	
				timestamp,
				co_asset_id,
				asset_ctrl_num,
				asset_description 
		FROM 	amasset	
		WHERE 	co_asset_id		= @MSKco_asset_id 

		SELECT @rowsfound = @rowsfound + @@rowcount 

		 
		SELECT 	@MSKco_asset_id = MIN(co_asset_id) 
		FROM 	amasset 
		WHERE 	co_asset_id 	> @MSKco_asset_id 
	END 
END

SELECT 
	timestamp,
	co_asset_id,
	asset_ctrl_num,
	asset_description
FROM #temp 

DROP TABLE #temp 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amastkey_vwFetch_sp] TO [public]
GO
