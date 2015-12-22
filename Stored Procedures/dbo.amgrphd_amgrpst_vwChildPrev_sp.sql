SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphd_amgrpst_vwChildPrev_sp]
(
	@rowsrequested	smCounter = 1,
	@modified_by	smUserID,
	@group_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@asset_ctrl_num 	smControlNumber
)
AS
 
DECLARE	@rowsfound	smCounter
DECLARE @MSKcompany_id	smCompanyID
DECLARE @MSKasset_ctrl_num	smControlNumber
 
CREATE TABLE #temp
(
	timestamp	varbinary(8)	NULL,
	group_id	int	NULL,
	company_id	smallint	NULL,
	asset_ctrl_num	char(16)	NULL,
	asset_description	varchar(40)	NULL
)
 
SELECT @rowsfound = 0
SELECT	@MSKcompany_id = @company_id
SELECT	@MSKasset_ctrl_num = @asset_ctrl_num
 
SELECT	@MSKasset_ctrl_num	= MAX(asset_ctrl_num)
FROM	amgrpast
WHERE	group_id	= @group_id
AND modified_by = @modified_by 
AND	company_id	= @MSKcompany_id
AND	asset_ctrl_num	< @MSKasset_ctrl_num
 
WHILE @MSKasset_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		timestamp,
		group_id,
		company_id,
		asset_ctrl_num,
		asset_description
	FROM	amgrpast_vw
	WHERE	group_id	= @group_id
	AND modified_by = @modified_by 

	AND		company_id	= @MSKcompany_id
	AND		asset_ctrl_num	= @MSKasset_ctrl_num
 
	SELECT @rowsfound = @rowsfound + @@rowcount
 
 
	SELECT @MSKasset_ctrl_num	= MAX(asset_ctrl_num)
	FROM amgrpast
	WHERE	group_id	= @group_id
	AND modified_by = @modified_by 

	AND	company_id	= @MSKcompany_id
	AND	asset_ctrl_num	< @MSKasset_ctrl_num
END
SELECT
	timestamp,
	@modified_by,
	group_id,
	company_id,
	asset_ctrl_num,
	asset_description
FROM	#temp
ORDER BY	company_id, asset_ctrl_num
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amgrphd_amgrpst_vwChildPrev_sp] TO [public]
GO
