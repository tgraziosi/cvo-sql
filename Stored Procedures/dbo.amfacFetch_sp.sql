SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amfacFetch_sp] 
( 
	@rowsrequested			smallint = 1,
	@company_id smCompanyID,
	@fac_mask				smAccountCode 
)
AS 

CREATE TABLE #temp 
( 
	timestamp 				varbinary(8) 	null,
	company_id 				int 			null,
	fac_mask				char(32) 		null, 
	fac_mask_description 	varchar(40) 	null, 
	last_modified_date	 	datetime	 	null,
	modified_by				int				null 
)

DECLARE @rowsfound 		smallint 
DECLARE @MSKfac_mask 	smAccountCode 

SELECT @rowsfound = 0 
SELECT @MSKfac_mask = @fac_mask 

IF EXISTS (SELECT 	* 
			FROM 	amfac 
			WHERE	company_id	= @company_id 
			AND		fac_mask 	= @MSKfac_mask)
BEGIN 
	WHILE @MSKfac_mask IS NOT NULL AND @rowsfound < @rowsrequested 
	BEGIN 
		INSERT INTO #temp 
		SELECT 
			timestamp,
			company_id,
			fac_mask,
			fac_mask_description,
			last_modified_date,
			modified_by 
		FROM 	amfac 
		WHERE 	company_id		= @company_id
		AND		fac_mask 		= @MSKfac_mask 

		SELECT @rowsfound = @rowsfound + @@rowcount 
		
		 
		SELECT 	@MSKfac_mask 	= MIN(fac_mask) 
		FROM 	amfac 
		WHERE 	company_id		= @company_id
		AND		fac_mask	 	> @MSKfac_mask 
	END 
END 

SELECT 
	timestamp,
	company_id,
	fac_mask,
	fac_mask_description,
	last_modified_date	= CONVERT(char(8), last_modified_date, 112),
	modified_by 
FROM #temp 
ORDER BY company_id, fac_mask
 
DROP TABLE #temp 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amfacFetch_sp] TO [public]
GO
