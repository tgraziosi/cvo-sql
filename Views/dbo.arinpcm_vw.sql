SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[arinpcm_vw]
				AS 
				SELECT	*
				FROM 	arinpchg
				WHERE	trx_type = 2032	 
GO
GRANT REFERENCES ON  [dbo].[arinpcm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpcm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpcm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpcm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpcm_vw] TO [public]
GO
