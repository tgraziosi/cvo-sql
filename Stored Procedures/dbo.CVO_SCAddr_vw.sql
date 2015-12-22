SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Author:		elabarbera
-- Create date: 12/12/12
-- Description:	Address Listing for all Sales Consultants
-- =============================================
CREATE PROCEDURE [dbo].[CVO_SCAddr_vw] 
AS
BEGIN
	SET NOCOUNT ON;

select territory_code as Terr, salesperson_name as Salesperson, addr2, addr3, addr4, addr_sort2 as email 
from arsalesp ARS 
where status_type = 1 and salesperson_name not like '%default%' and territory_code <> 80620 
order by ARS.territory_code


END

GO
