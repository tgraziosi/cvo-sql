SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxast_vwNext_sp]
(
	@rowsrequested	smCounter = 1,
	@co_trx_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@asset_ctrl_num 	smControlNumber
)
AS
 
DECLARE	@rowsfound	smCounter
DECLARE @MSKasset_ctrl_num	smControlNumber
 
CREATE TABLE #temp
(
	timestamp	varbinary(8)	NULL,
	co_trx_id	int	NULL,
	company_id	smallint	NULL,
	asset_ctrl_num	char(16)	NULL,
	asset_description	varchar(40)	NULL
)
 
SELECT @rowsfound = 0
SELECT	@MSKasset_ctrl_num = @asset_ctrl_num
 
SELECT	@MSKasset_ctrl_num	= MIN(asset_ctrl_num)
FROM	amtrxast
WHERE	co_trx_id	= @co_trx_id
AND	company_id	= @company_id
AND	asset_ctrl_num	> @MSKasset_ctrl_num
 
WHILE @MSKasset_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		timestamp,
		co_trx_id,
		company_id,
		asset_ctrl_num,
		asset_description
	FROM	amtrxast_vw
	WHERE	co_trx_id	= @co_trx_id
	AND		company_id	= @company_id
	AND		asset_ctrl_num	= @MSKasset_ctrl_num
 
	SELECT @rowsfound = @rowsfound + @@rowcount
 
 
	SELECT @MSKasset_ctrl_num	= MIN(asset_ctrl_num)
	FROM amtrxast
	WHERE	co_trx_id	= @co_trx_id
	AND	company_id	= @company_id
	AND	asset_ctrl_num	> @MSKasset_ctrl_num
END
SELECT
	timestamp,
	co_trx_id,
	company_id,
	asset_ctrl_num,
	asset_description
FROM	#temp
ORDER BY	asset_ctrl_num
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxast_vwNext_sp] TO [public]
GO
