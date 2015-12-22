SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW	[dbo].[apinpchg_vw]
AS
	SELECT * 
	FROM	apinpchg
	WHERE	trx_type = 4091

GO
GRANT REFERENCES ON  [dbo].[apinpchg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apinpchg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpchg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpchg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpchg_vw] TO [public]
GO
