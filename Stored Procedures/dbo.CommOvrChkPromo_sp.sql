SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 4/18/2013
-- Description:	Check Incorrect Commissions for Promo Overrides
-- exec CommOvrChkPromo_sp '4/1/2013', '4/30/2013'
-- =============================================
CREATE PROCEDURE [dbo].[CommOvrChkPromo_sp] 
	@DateFrom datetime,
	@DateTo datetime
AS
BEGIN
	SET NOCOUNT ON;

--DECLARE @DateFrom datetime
--DECLARE @DateTo datetime
--SET  @DateFrom = '4/1/2013'
--SET  @DateTo = '4/30/2013'
	SET @DateTo=dateadd(second,-1,@dateTo)
	SET @DateTo=dateadd(day,1,@dateTo)

-- Mismatched Promo Commission Overrides vs Orders
select distinct ship_to_region, salesperson, t4.commission as 'CustCommOVR', commission_pct as 'Comm On Ord', t3.commission as 'Promo Comm', t2.promo_id, t2.promo_level, TYPE, STATUS, date_entered, date_shipped, cust_code, t1.order_no, t1.ext, t1.user_category as OrdType from orders_all t1
join cvo_orders_all t2 on t1.order_no=t2.order_no and t1.ext=t2.ext
join cvo_promotions t3 on t2.promo_id=t3.promo_id and t2.promo_level=t3.promo_level
left outer join cvo_armaster_all t4 on t1.cust_code=t4.customer_code
where STATUS <> 'V' and t3.commissionable = 1
and (t3.void IS NULL OR t3.VOID = 'N')  AND  (promo_end_date > getdate() OR promo_end_Date IS NULL)
and t4.ship_to =''
and t2.commission_pct <> t3.commission
AND DATE_ENTERED BETWEEN @DateFrom and @DateTo
ORDER BY PROMO_ID, DATE_ENTERED


END

GO
