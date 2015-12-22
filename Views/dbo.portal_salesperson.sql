SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[portal_salesperson]  
AS  
  
  
select salesperson_code from arsalesp  
where salesperson_code >'A%'  
  
GO
GRANT SELECT ON  [dbo].[portal_salesperson] TO [public]
GO
GRANT INSERT ON  [dbo].[portal_salesperson] TO [public]
GO
GRANT DELETE ON  [dbo].[portal_salesperson] TO [public]
GO
GRANT UPDATE ON  [dbo].[portal_salesperson] TO [public]
GO
