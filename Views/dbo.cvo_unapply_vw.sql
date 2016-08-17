SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_unapply_vw]
AS

	SELECT	DISTINCT doc_ctrl_num,
			customer_code,
			amt_net 
	FROM	artrx_all (NOLOCK) 
	WHERE	trx_type = 2111

GO
GRANT SELECT ON  [dbo].[cvo_unapply_vw] TO [public]
GO
