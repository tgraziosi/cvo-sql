SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
create view [dbo].[cvo_driverdet_q_vw]    
AS    
    
    
select * from cvo_driverdet_q
GO
GRANT SELECT ON  [dbo].[cvo_driverdet_q_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_driverdet_q_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_driverdet_q_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_driverdet_q_vw] TO [public]
GO
