SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[CVOarnarelAudit_vw]
AS
SELECT parent, child, relation_code, CASE WHEN movement_flag=0 THEN 'Removed' ELSE 'Added' END AS movement_flag, audit_date, CONVERT(VARCHAR(20),audit_datetime, 100) AS audit_datetime FROM CVOarnarelAudit
GO
GRANT SELECT ON  [dbo].[CVOarnarelAudit_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVOarnarelAudit_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVOarnarelAudit_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVOarnarelAudit_vw] TO [public]
GO
