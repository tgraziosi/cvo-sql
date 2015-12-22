SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 6/3/2013
-- Description:	List Customers with Designations and No primary
-- EXEC CVO_Cust_NoPriDesig_ssrs_SP 
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Cust_NoPriDesig_ssrs_SP] 
AS
BEGIN
	SET NOCOUNT ON;

IF(OBJECT_ID('tempdb.dbo.#DesigList') is not null)
drop table dbo.#DesigList
      ;WITH C AS 
            ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select Distinct customer_code,
                              STUFF ( ( SELECT '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE customer_code = C.customer_code
                              AND (END_DATE IS NULL or END_DATE >=getdate())
                              FOR XML PATH ('') ), 1, 1, ''  ) AS DLIST
      INTO #DesigList
      FROM C
-- select * from #DesigList

IF(OBJECT_ID('tempdb.dbo.#DesigPri') is not null)
drop table dbo.#DesigPri
select distinct customer_code, code, start_date, end_date into #DesigPri from cvo_cust_designation_codes where primary_flag=1
-- select * from #DesigPri


select distinct t1.customer_code, t2.address_name, DLIST as ActiveDesigs, t4.code as PrimaryCode, t4.start_date as PriStart, t4.end_date as PriEnd
from cvo_cust_designation_codes t1 
join CVO_DESIGNATION_CODES T11 ON T1.CODE=T11.CODE
join armaster t2 on t1.customer_code=t2.customer_code 
left join #DesigList t3 on t1.customer_code=t3.customer_code 
left join #DesigPri t4  on t1.customer_code=t4.customer_code 
where t2.address_type=0
and t11.rebate='y'
and t4.code is null   -- remove this to see all customers
and dlist is not null   -- remove this to see those with primary

END

GO
