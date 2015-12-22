SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_dist_wc_vw]
AS

SELECT	DISTINCT weight_code
FROM	CVO_weights (NOLOCK)

GO
GRANT REFERENCES ON  [dbo].[cvo_dist_wc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_dist_wc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_dist_wc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_dist_wc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_dist_wc_vw] TO [public]
GO
