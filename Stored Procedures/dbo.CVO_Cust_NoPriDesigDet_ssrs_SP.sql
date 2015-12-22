SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 6/3/2013
-- Description:	List Customers and Designations with no Primary
-- EXEC CVO_Cust_NoPriDesigDet_ssrs_SP 
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Cust_NoPriDesigDet_ssrs_SP] 
AS
BEGIN
	SET NOCOUNT ON;

select distinct 
	(select address_name 
	from armaster (nolock) t11 
	where t1.customer_code=t11.customer_code and t11.ship_to_code='') as CustName, 
t1.*,
row_number() over(partition by t1.Customer_code order by  t1.Customer_code, t1.code) AS Num,
ISNULL((select parent from arnarel t2 where t1.customer_code = t2.child),'') as Parent,
t3.territory_code as Terr, 
(select sum(rolling12net) from cvo_rad_shipto t2 where t1.customer_code=t2.customer and t2.yyyymmdd =CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(getdate())-1),getdate()),101)) as R12, 
t3.price_code,
(SELECT ITEM FROM cvo_cust_designation_codes_audit a where a.id = ca.id) as ITEM,
(SELECT Audit_Date FROM cvo_cust_designation_codes_audit a WHERE a.id = ca.id) as AUDIT_DATE,
(SELECT user_ID FROM cvo_cust_designation_codes_audit a WHERE a.id=ca.id) as UpdateUser
from cvo_cust_designation_codes t1
join cvo_designation_codes t2 on t1.code=t2.code
join armaster t3 on t1.customer_code=t3.customer_code
left outer join 
(select customer_code, max(id) id from 
	cvo_cust_designation_codes_audit group by customer_code
) ca on ca.customer_code = t1.customer_code
where t1.customer_code in 
	(select customer_code 
	from cvo_cust_designation_codes t1 
	join cvo_designation_codes t2 on t1.code=t2.code 
	where t2.rebate='y'
	group by Customer_code 
	having sum(primary_flag)=0  )
and t3.address_type=0
and t2.rebate='y'
and ( end_Date is NULL OR end_date > getdate() )
order by customer_code, code

END



GO
