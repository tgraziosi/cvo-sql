SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[arinpchg_vw]
				AS 
				SELECT	*
				FROM 	arinpchg
				WHERE	trx_type = 2031	 
GO
GRANT REFERENCES ON  [dbo].[arinpchg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpchg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpchg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpchg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpchg_vw] TO [public]
GO
