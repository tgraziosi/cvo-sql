SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imeinvd_vw] AS 


SELECT	* FROM [CVO_Control]..imardtl WHERE trx_type = 2031
                                             
GO
GRANT REFERENCES ON  [dbo].[imeinvd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imeinvd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imeinvd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imeinvd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imeinvd_vw] TO [public]
GO
