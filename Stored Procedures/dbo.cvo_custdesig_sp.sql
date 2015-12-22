SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		ELABARBERA
-- Create date: 3/4/2013
-- Description:	Customer Designations and date view
-- EXEC cvo_custdesig_sp
-- =============================================
CREATE PROCEDURE [dbo].[cvo_custdesig_sp] 
AS
BEGIN

	SET NOCOUNT ON;

select t1.customer_code, t2.address_name, t1.code, t3.description, 
case when t3.void = 1 THEN 'VOID' ELSE '' END AS Voided,
case when t3.date_reqd = 1 THEN 'Y' ELSE '' END AS DateRequired,
case when primary_flag = 1 THEN 'Y' ELSE '' END AS Pri,
t1.start_date, t1.end_date from cvo_cust_designation_codes t1
join armaster t2 on t1.customer_code=t2.customer_code
join cvo_designation_codes t3 on t1.code=t3.code
where t2.address_type='0'
and t3.rebate='y'
order by Code, customer_code

END


GO
