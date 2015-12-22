SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW	[dbo].[apinpdm_vw]
AS
	SELECT * 
	FROM	apinpchg
	WHERE	trx_type = 4092

GO
GRANT REFERENCES ON  [dbo].[apinpdm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apinpdm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpdm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpdm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpdm_vw] TO [public]
GO
