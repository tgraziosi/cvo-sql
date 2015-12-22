SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--v1.0 CB 24/07/2013 - Issue #927 - Buying Group Switching

CREATE VIEW [dbo].[cvo_bgs_audit_vw] 
AS
	SELECT	audit_date, 
			userid, 
			rec_type, 
			parent,
			child, 
			LEFT(buying_group_no,30) buying_group_no,
			action_date
	FROM	dbo.cvo_buying_group_switch_audit (NOLOCK)
GO
GRANT REFERENCES ON  [dbo].[cvo_bgs_audit_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_bgs_audit_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_bgs_audit_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_bgs_audit_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_bgs_audit_vw] TO [public]
GO
