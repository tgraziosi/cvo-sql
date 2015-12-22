SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		elabarbera
-- Create date: 2/27/2013
-- Description:	List of Customers Adding, Moving or Leaving Parent BG's
-- =============================================
CREATE PROCEDURE [dbo].[CustBGMovement_sp] 
-- exec CustBGMovement_sp '2/1/2013','2/20/2013'

@DFrom datetime,
@DateTo datetime

AS
BEGIN
	SET NOCOUNT ON;
-- list of bg customer changes

DECLARE @DTo DATETIME
SET @Dto = dateadd(second, -1, dateadd(day, datediff(day, 0, @DATETO)+1, 0))

select distinct child, address_name, audit_datetime, 
ISNULL((select top 1 Parent from cvoarnarelAudit t2 where movement_flag = '1' and t1.child=t2.child),'')NewParent, 
ISNULL((select top 1 address_name from armaster where customer_code = ISNULL((select top 1 Parent from cvoarnarelAudit t2 where movement_flag = '1' and t1.child=t2.child),'')),'') NewParentName,
ISNULL((select top 1 Parent from cvoarnarelAudit t3 where movement_flag = '0' and t1.child=t3.child),'')OrigParent,
ISNULL((select top 1 address_name from armaster where customer_code = ISNULL((select top 1 Parent from cvoarnarelAudit t3 where movement_flag = '0' and t1.child=t3.child),'')),'') OrigParentName
from CVOarnarelAudit t1 
JOIN ARMASTER T2 ON T1.CHILD=T2.CUSTOMER_CODE
where audit_datetime BETWEEN @DFrom and @DTo 
AND ADDRESS_TYPE=0
order by AUDIT_DATETIME

END
GO
