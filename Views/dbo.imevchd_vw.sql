SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imevchd_vw] AS 

SELECT 	* FROM [CVO_Control]..imapdtl WHERE trx_type = 4091


                                             
GO
GRANT REFERENCES ON  [dbo].[imevchd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imevchd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imevchd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imevchd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imevchd_vw] TO [public]
GO
