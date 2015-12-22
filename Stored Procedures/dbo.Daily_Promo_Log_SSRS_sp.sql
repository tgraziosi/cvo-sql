SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Procedure [dbo].[Daily_Promo_Log_SSRS_sp]
@DFrom datetime,
@DTo datetime

AS
Begin

IF(OBJECT_ID('tempdb.dbo.#T1') is not null)
drop table dbo.#T1

IF(OBJECT_ID('tempdb.dbo.#T2') is not null)
drop table dbo.#T2


;With C AS
(
select 
o.ORDER_NO,
o.cust_code, 
o.ext, 
DATEADD(dd, DATEDIFF(dd, 0, date_entered),0)AS date_entered, 
isnull(cvo.promo_id,'') AS promo_id,
isnull(cvo.promo_level,'') as promo_level,
o.user_category as OrderType,
o.type +'-'+left(o.user_category,2) as Type

from orders o (nolock) 
inner join cvo_orders_all cvo (nolock)
on o.order_no = cvo.order_no and o.ext = cvo.ext
where o.status <> 'V' and o.void = 'N' and o.type = 'I'
-- and left(o.user_category,2) <> 'RX'		-- CVO excluded 2/27/13 EL (for RX-PC's
and o.user_category NOT IN ('RX-RB','RX-PL','RX-LP','RX')	-- EL
and right(o.user_category,2) not in ('PM') 
and o.who_entered <> 'BACKORDR'
and date_entered Between @DFrom And @DTo
)

Select * into #T1 From C

;With C AS
(
select promo_id,promo_level,promo_name from CVO_promotions
Where  promo_start_date <= @DFrom 
-- AND promo_end_date >= @DTo
and promo_end_date >=getdate() -- 10/29/2013 - all current promos in period
and void <> 'V' -- tag 121913 - exclude voids
)

Select * into #T2 From C

--;With C AS ( 
Select 
o.cust_code,
case
when o.promo_id <> '' then o.promo_id -- 10/29/2013
when p.promo_id = '' then '-'
when p.promo_id IS NULL then '-' 
else p.promo_id end AS promo_id,
case
when o.promo_level <> '' then o.promo_level -- 10/29/2013
when p.promo_level= '' then '-'
when p.promo_level IS NULL then '-' 
else p.promo_level end AS promo_level, p.promo_name,
ORDER_NO,ext,date_entered,
--isnull(cvo.promo_id,'') AS promo_id,
--isnull(cvo.promo_level,'') as promo_level,
OrderType,Type

From #T1 o FULL OUTER JOIN #T2 p
on o.promo_id = p.promo_id AND o.promo_level = p.promo_level
order by promo_id,promo_level
--)

--Select * from c
--Where promo_id <> '-'
--order by promo_id,promo_level



End



GO
