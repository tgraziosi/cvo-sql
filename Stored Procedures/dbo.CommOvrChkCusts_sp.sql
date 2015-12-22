SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 4/18/2013
-- Description:	Check Incorrect Commissions for Customer Overrides
-- exec CommOvrChkCusts_sp '4/1/2013', '4/30/2013'
-- =============================================
CREATE PROCEDURE [dbo].[CommOvrChkCusts_sp]
	-- Add the parameters for the stored procedure here
	@DateFrom datetime,
	@DateTo datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--DECLARE @DateFrom datetime
--DECLARE @DateTo datetime
--SET  @DateFrom = '4/1/2013'
--SET  @DateTo = '4/30/2013'
	SET @DateTo=dateadd(second,-1,@dateTo)
	SET @DateTo=dateadd(day,1,@dateTo)
	
-- Mismatched Customer Commission Overrides vs Orders
select distinct ship_to_region, salesperson, t4.commission as 'CustCommOVR', t3.commission as 'Promo Comm', commission_pct as 'Comm On Ord',  t2.promo_id, t2.promo_level, TYPE, STATUS, date_entered, date_shipped, cust_code, t1.order_no, t1.ext, t1.user_category as OrdType
from orders_all t1
join cvo_orders_all t2 on t1.order_no=t2.order_no and t1.ext=t2.ext
join cvo_armaster_all t4 on t1.cust_code=t4.customer_code
full outer join cvo_promotions t3 on t2.promo_id=t3.promo_id and t2.promo_level=t3.promo_level
where status <> 'v'
and DATE_ENTERED BETWEEN @DateFrom and @DateTo
and t4.commission <> commission_pct
and ( t3.commission IS NULL or t3.commission <> commission_pct)
order by cust_code



END

GO
