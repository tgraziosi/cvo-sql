SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amtrxdef_rpt_vw]
AS 
SELECT trx_short_name 
	FROM amtrxdef  where display_in_reports <> 0 
 UNION SELECT  'All Types' 
GO
GRANT REFERENCES ON  [dbo].[amtrxdef_rpt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amtrxdef_rpt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amtrxdef_rpt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amtrxdef_rpt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtrxdef_rpt_vw] TO [public]
GO
