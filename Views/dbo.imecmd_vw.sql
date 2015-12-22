SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imecmd_vw] AS 


SELECT	* FROM [CVO_Control]..imardtl WHERE trx_type = 2032
                                             
GO
GRANT REFERENCES ON  [dbo].[imecmd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imecmd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imecmd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imecmd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imecmd_vw] TO [public]
GO
