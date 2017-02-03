SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
CREATE VIEW [dbo].[apgltcrecon_vw]  
AS  
   SELECT * from gltcrecon   
    WHERE trx_type = 4091  
       OR trx_type = 4092  
GO
GRANT REFERENCES ON  [dbo].[apgltcrecon_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apgltcrecon_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apgltcrecon_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apgltcrecon_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apgltcrecon_vw] TO [public]
GO
