SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[CVO_CollCalls_vw]
AS
-- tag = 042413 - remove cr lf s in comments
SELECT	
	c.customer_code,
	a.customer_name,
	c.comment_date,
	c.doc_ctrl_num,
	dbo.cvo_fn_rem_crlf(c.comments) comments,
	c.user_name as created_by,
	c.updated_comment_date,
	c.updated_user_name as updated_by
FROM
	cc_comments c
	LEFT OUTER JOIN arcust a ON c.customer_code = a.customer_code



GO
GRANT REFERENCES ON  [dbo].[CVO_CollCalls_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_CollCalls_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_CollCalls_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_CollCalls_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_CollCalls_vw] TO [public]
GO
