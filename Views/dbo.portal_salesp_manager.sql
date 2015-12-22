SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[portal_salesp_manager]
AS


select salesperson_code,sales_mgr_code from arsalesp
where salesperson_code>'A'
GO
