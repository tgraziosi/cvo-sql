SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammshdr_ammsst_vwChildLast_sp]
(
	@rowsrequested					smCounter = 1,
	@mass_maintenance_id 	smSurrogateKey,
	@company_id						smCompanyID

)
AS
 
DECLARE	@rowsfound			smCounter
DECLARE @MSKasset_ctrl_num	smControlNumber

CREATE TABLE #temp ( timestamp varbinary(8) NULL, mass_maintenance_id int NULL, company_id smallint NULL, asset_ctrl_num char(16) NULL, asset_description varchar(40) NULL, activity_state smallint NULL, comment varchar(255) NULL )
 
SELECT @rowsfound = 0
 
SELECT	@MSKasset_ctrl_num	= MAX(asset_ctrl_num)
FROM	ammasast
WHERE	mass_maintenance_id	= @mass_maintenance_id
AND		company_id			= @company_id
 
IF @MSKasset_ctrl_num IS NULL
BEGIN
	DROP TABLE #temp
	RETURN
END
 
INSERT INTO #temp
(
	 timestamp, mass_maintenance_id, company_id, asset_ctrl_num, asset_description, activity_state, comment
	)
SELECT
	 timestamp, mass_maintenance_id, company_id, asset_ctrl_num, asset_description, activity_state, comment
FROM	ammasast_vw
WHERE	mass_maintenance_id = @mass_maintenance_id
AND		company_id			= @company_id
AND		asset_ctrl_num		= @MSKasset_ctrl_num
 
SELECT	@rowsfound = @@rowcount
 
SELECT	@MSKasset_ctrl_num	= MAX(asset_ctrl_num)
FROM	ammasast
WHERE	mass_maintenance_id	= @mass_maintenance_id
AND		company_id			= @company_id
AND		asset_ctrl_num		< @MSKasset_ctrl_num
 
WHILE @MSKasset_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		 timestamp, mass_maintenance_id, company_id, asset_ctrl_num, asset_description, activity_state, comment
	FROM 	ammasast_vw
	WHERE	mass_maintenance_id	= @mass_maintenance_id
	AND		company_id			= @company_id
	AND		asset_ctrl_num		= @MSKasset_ctrl_num
 
	SELECT @rowsfound = @rowsfound + @@rowcount
 
	SELECT 	@MSKasset_ctrl_num	= MAX(asset_ctrl_num)
	FROM 	ammasast
	WHERE	mass_maintenance_id	= @mass_maintenance_id
	AND		company_id			= @company_id
	AND		asset_ctrl_num		< @MSKasset_ctrl_num
END

SELECT
	timestamp, mass_maintenance_id, company_id, asset_ctrl_num, asset_description, activity_state, comment
FROM	#temp 
ORDER BY	asset_ctrl_num
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammshdr_ammsst_vwChildLast_sp] TO [public]
GO
