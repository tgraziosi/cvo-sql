SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW	[dbo].[arafinv_vw]
AS
SELECT	*
FROM 	arinpchg
WHERE	trx_type = 2021	


GO
GRANT REFERENCES ON  [dbo].[arafinv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arafinv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arafinv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arafinv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arafinv_vw] TO [public]
GO
