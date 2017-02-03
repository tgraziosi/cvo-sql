SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
CREATE VIEW [dbo].[argltcrecon_vw]  
AS  
   SELECT * from gltcrecon   
    WHERE trx_type = 2031   
       OR trx_type = 2032  
GO
GRANT REFERENCES ON  [dbo].[argltcrecon_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[argltcrecon_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[argltcrecon_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[argltcrecon_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[argltcrecon_vw] TO [public]
GO
