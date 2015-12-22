SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imedmd_vw] AS 

SELECT * FROM [CVO_Control]..imapdtl WHERE trx_type = 4092


                                             
GO
GRANT REFERENCES ON  [dbo].[imedmd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imedmd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imedmd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imedmd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imedmd_vw] TO [public]
GO
