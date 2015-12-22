SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amtrxast_vwFirst_sp]
(
	@rowsrequested	smCounter = 1,
	@co_trx_id                   	smSurrogateKey,
	@company_id                  	smCompanyID
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
 
SELECT	@MSKasset_ctrl_num	= MIN(asset_ctrl_num)
FROM	amtrxast, amOrganization_vw o 
WHERE	co_trx_id	= @co_trx_id
AND	company_id	= @company_id
AND	amtrxast.org_id = o.org_id
 
IF @MSKasset_ctrl_num IS NULL
BEGIN
	DROP TABLE #temp
	RETURN
END
 
INSERT INTO #temp
SELECT
	amtrxast_vw.timestamp,
	amtrxast_vw.co_trx_id,
	amtrxast_vw.company_id,
	amtrxast_vw.asset_ctrl_num,
	amtrxast_vw.asset_description
FROM	amtrxast_vw, amasset, amOrganization_vw o 
WHERE	amtrxast_vw.co_trx_id = @co_trx_id
AND		amtrxast_vw.company_id = @company_id
AND		amtrxast_vw.asset_ctrl_num	= @MSKasset_ctrl_num
AND 	amtrxast_vw.asset_ctrl_num = amasset.asset_ctrl_num
AND	amasset.org_id = o.org_id
 
SELECT	@rowsfound = @@rowcount
 
SELECT	@MSKasset_ctrl_num	= MIN(asset_ctrl_num)
FROM	amtrxast, amOrganization_vw o 
WHERE	co_trx_id	= @co_trx_id
AND	company_id	= @company_id
AND	asset_ctrl_num	> @MSKasset_ctrl_num
AND	amtrxast.org_id = o.org_id
 
WHILE @MSKasset_ctrl_num IS NOT NULL AND @rowsfound < @rowsrequested
BEGIN
 
	INSERT INTO #temp
	SELECT
		amtrxast_vw.timestamp,
		amtrxast_vw.co_trx_id,
		amtrxast_vw.company_id,
		amtrxast_vw.asset_ctrl_num,
		amtrxast_vw.asset_description
	FROM	amtrxast_vw, amasset, amOrganization_vw o 
	WHERE	amtrxast_vw.co_trx_id	= @co_trx_id
	AND		amtrxast_vw.company_id	= @company_id
	AND		amtrxast_vw.asset_ctrl_num	= @MSKasset_ctrl_num
	AND 	amtrxast_vw.asset_ctrl_num = amasset.asset_ctrl_num
	AND	amasset.org_id = o.org_id
 
	SELECT @rowsfound = @rowsfound + @@rowcount
 
 
	SELECT @MSKasset_ctrl_num	= MIN(asset_ctrl_num)
	FROM amtrxast, amOrganization_vw o 
	WHERE	co_trx_id	= @co_trx_id
	AND	company_id	= @company_id
	AND	asset_ctrl_num	> @MSKasset_ctrl_num
	AND	amtrxast.org_id = o.org_id
END
SELECT
	timestamp,
	co_trx_id,
	company_id,
	asset_ctrl_num,
	asset_description
FROM	#temp
ORDER BY	co_trx_id, company_id, asset_ctrl_num
 
DROP TABLE #temp
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amtrxast_vwFirst_sp] TO [public]
GO
