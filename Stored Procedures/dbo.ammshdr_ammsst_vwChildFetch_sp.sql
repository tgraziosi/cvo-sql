SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammshdr_ammsst_vwChildFetch_sp]
(
	@rowsrequested	smCounter = 1,
	@mass_maintenance_id smSurrogateKey, @company_id smSurrogateKey, @asset_ctrl_num smControlNumber
)
AS

SET ROWCOUNT @rowsrequested
 
SELECT
	timestamp, mass_maintenance_id, company_id, asset_ctrl_num, asset_description, activity_state, comment 
FROM	ammasast_vw
WHERE	mass_maintenance_id	= @mass_maintenance_id
AND		company_id			= @company_id
AND		asset_ctrl_num		>= @asset_ctrl_num
ORDER BY	 asset_ctrl_num
 
SET ROWCOUNT 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammshdr_ammsst_vwChildFetch_sp] TO [public]
GO
