SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--  EXEC SSRS_Territory_Planner_terr_sp '10/1/2014','09/30/2015', 20201

CREATE Procedure [dbo].[SSRS_Territory_Planner_terr_sp]
@DF datetime = null,                                    
@DT datetime = null,	
@Terr varchar(1024) = NULL,
@coll VARCHAR(1024) = null

AS
Begin

-- TERITORY PLANNER
-------- CREATED BY *Elizabeth LaBarbera*  9/24/12
-- rewrite 040115 tag

---- for testing
--DECLARE @DF datetime, @DT datetime, @terr varchar(1024)
--select @terr = null, @dt = getdate(), @df = dateadd(yy, datediff(yy,0, getdate()), 0)	
----

DECLARE @DateFromLY datetime, @DateToLY datetime, @datefrom datetime, @dateto datetime

declare @Territory varchar(1024) , @collection VARCHAR(1024)

select @territory = @terr, @datefrom = @df, @dateto = @dt
						 , @datefromly = dateadd(yy,-1,@df), @datetoly = dateadd(yy,-1, @dt)
						 , @collection = @coll


IF(OBJECT_ID('tempdb.dbo.#Territory') is not null)  drop table dbo.#Territory

--declare @Territory varchar(1000)
--select  @Territory = null

create table #territory (territory varchar(8))

if @Territory is null
begin
 insert into #territory (territory)
 select distinct territory_code from armaster (nolock) 
 where address_type <> 9 
end
else
begin
 insert into #territory (territory)
 select listitem from dbo.f_comma_list_to_table(@Territory)
END

create table #coll (coll varchar(12))

if @collection is NULL 
begin
 insert into #coll (coll)
 select distinct kys from category (nolock) 
 WHERE void = 'N'
end
else
begin
 insert into #coll (coll)
 select listitem from dbo.f_comma_list_to_table(@collection)
END


-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff') is not null)  drop table #Rank_Aff  
select a.customer_code as from_cust, 
	   a.ship_to_code as shipto, 
	   a.affiliated_cust_code as to_cust
into #Rank_Aff
from armaster a (nolock) 
inner join armaster b (nolock) on a.affiliated_cust_code = b.customer_code and a.ship_to_code = b.ship_to_code
where a.status_type <> 1 and a.address_type <> 9 
and a.affiliated_cust_code<> '' and a.affiliated_cust_code is not null
and b.status_type = 1 and b.address_type <> 9
--select @@rowcount
--select * from #Rank_Aff

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff_All') is not null) drop table dbo.#Rank_Aff_All
select x.cust, x.code INTO #Rank_Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Rank_Aff 
UNION all
select to_cust AS CUST,'A' Code from #Rank_Aff ) X
--SELECT * FROM #Rank_Aff_All 


IF(OBJECT_ID('tempdb.dbo.#OldestOrderDate') is not null)
drop table dbo.#OldestOrderDate
SELECT CUSTOMER_CODE, SHIP_TO_CODE, 
	(SELECT TOP 1 t1.DATE_ENTERED
	FROM ORDERS_ALL (NOLOCK) T1
	JOIN ORD_LIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
	join inv_master (NOLOCK) t3 ON t2.part_no=t3.part_no
	where t1.cust_code=ar.customer_code and t1.ship_to=ar.ship_to_code 
	and t1.status='t'
	and t1.type='i'
	and t1.who_entered <> 'backordr'
	AND t3.type_code in ('frame','sun')
	and t1.DATE_ENTERED between dateadd(day,1,dateadd(year,-1,@DateTo)) and @DateTo
	AND t1.user_category not like 'rx%'
	GROUP BY t1.cust_code, t1.ship_to, DATE_ENTERED
	HAVING COUNT(t2.ordered) >=5
	ORDER BY CUST_CODE, t1.SHIP_TO, DATE_ENTERED desc) as OldestSTOrdDate
INTO #OldestOrderDate
from armaster AR (nolock)
order by customer_code, ship_to_code

-- Get Customer#, Shipto#, Name, Addr, City, State, Zip, Phone, Fax, Contact
-- Add 0/9 Status to Customer Data
-- add in Parent &/or BG
IF(OBJECT_ID('tempdb.dbo.#custinfo') is not null) drop table dbo.#custinfo

SELECT 

 RIGHT(ar.customer_code,5) customer_code
, ar.ship_to_code
, ar.territory_code
, MAX(car.door) door
, MIN(ISNULL(t3.code,'A')) Status
, MIN(ISNULL(ar.Address_name,'')) address_name
, MIN(ISNULL(ar.addr2,'')) addr2
, MIN(ISNULL(ar.City,'')) city
, MIN(ISNULL(ar.State,'')) state
, MIN(ISNULL(ar.Postal_code,'')) postal_code
, MIN(ISNULL(ar.contact_phone,'')) contact_phone
, MIN(isnull(ar.tlx_twx,'')) tlx_twx
, MIN(ISNULL(ar.contact_email,'')) contact_email
, MIN(ISNULL(ar.contact_name,'')) contact_name  
, MIN(ISNULL(case when ar.customer_code = art.parent then '' else art.parent END,'')) as Parent
, MIN(ISNULL(arm.address_name,'')) AS m_address
, MIN(ISNULL(arm.addr2,'')) AS m_addr2
, MIN(ISNULL(arm.city,'')) AS m_city
, MIN(ISNULL(arm.STATE,'')) AS m_state
, MIN(ISNULL(arm.postal_code,'')) AS m_postal_code
, MIN(ISNULL(arm.contact_phone,'')) AS m_contact_phone
, MIN(ISNULL(arm.tlx_twx,'')) AS m_tlx_twx
, MIN(ISNULL(arm.contact_email,'')) AS m_contact_email
, MIN(ISNULL(arm.contact_name,'')) AS m_contact_name
, MIN(ISNULL(carm.door,'')) as m_door
, oldeststorddate = (select min(OldestSTOrdDate) from #OldestOrderDate o 
		where RIGHT(o.customer_code,5) = RIGHT(ar.customer_code,5) AND ar.ship_to_code = o.ship_to_code)
, m_oldeststorddate = (select min(OldestSTOrdDate) from #OldestOrderDate o 
		where RIGHT(o.customer_code,5) = RIGHT(ar.customer_code,5))

INTO #custinfo
FROM 
#territory t 
inner join armaster ar (nolock) on t.territory = ar.territory_code
inner join cvo_armaster_all car (nolock) on ar.customer_code=car.customer_code and ar.ship_to_code=car.ship_to
full outer join #rank_aff_all t3 (nolock) on ar.customer_code = t3.cust
left outer join artierrl (nolock) art on art.rel_cust = ar.customer_code
-- for master customer info
left outer join armaster arm (nolock) on arm.customer_code = ar.customer_code and arm.ship_to_code = ''
left outer join cvo_armaster_all carm (nolock) on carm.customer_code = arm.customer_code and carm.ship_to = arm.ship_to_code

WHERE ar.ADDRESS_TYPE <> 9
GROUP BY 
RIGHT(ar.customer_code,5) 
, ar.ship_to_code
, ar.territory_code

-- select * from #custinfo where customer_code like '%41407'

-- Select Net Sales

IF(OBJECT_ID('tempdb.dbo.#netsales') is not null) drop table dbo.#netsales

select DISTINCT ar.territory_code, RIGHT(ar.customer_code,5) customer_code, ar.ship_to_code
, sbm.tyly 
, sbm.ordertype
, brand
, demographic  
, itemtype 
, anet
, areturns
, qnet
, qreturns
, promo_flg = CASE WHEN sbm.promo_id > '' AND EXISTS (SELECT 1 FROM #coll WHERE coll = sbm.brand) THEN 'Y'  ELSE '' end

into #netsales

from #territory t 
inner join armaster ar (nolock) on t.territory = ar.territory_code 
inner join
(select RIGHT(customer,5) customer, ship_to
, i.category brand
, demographic = case when ia.category_2 like '%child%' then 'Kids' else 'Adult' END 
, itemtype = i.type_code
, ordertype = case when left(sbm.user_category,2) = 'rx' then 'RX' else 'ST' end 
, TYLY = case when yyyymmdd >= @datefrom then 'TY' else 'LY' end 
-- , TYLY = case when yyyymmdd >= '01/01/2015' then 'TY' else 'LY' end 
, sum(anet) anet
, sum(case when return_code = '' then areturns else 0 end) areturns
, sum(qnet) qnet
, sum(case when return_code = '' then qreturns else 0 end) qreturns
, MAX(ISNULL(sbm.promo_id,'')) promo_id
 FROM  inv_master i 
 inner join inv_master_add ia on ia.part_no = i.part_no
 INNER JOIN cvo_sbm_details sbm on i.part_no = sbm.part_no
 
where (yyyymmdd between @datefromly and @datetoly or
	   yyyymmdd between @datefrom and @dateto )
-- where yyyymmdd between '01/01/2014' and '03/31/2015'
	-- and return_code in ( '', 'WTY')
	and i.type_code in ('frame','sun','parts')
group by RIGHT(customer,5), ship_to
 , i.category
 , case when ia.category_2 like '%child%' then 'Kids' else 'Adult' END 
 , i.type_code
 , case when left(sbm.user_category,2) = 'rx' then 'RX' else 'ST' end  
, case when yyyymmdd >= @datefrom then 'TY' else 'LY' end 
-- , case when yyyymmdd >= '01/01/2015' then 'TY' else 'LY' end 
 ) sbm on sbm.customer = RIGHT(ar.customer_code,5) AND sbm.ship_to = ar.ship_to_code

 -- select * from #netsales where customer_code like '%41407' 

 insert #netsales 
 select territory_code, customer_code, ship_to_code, 'ST','TY', brand, demographic, itemtype ,0,0,0,0, ''
 from 
 (
 (select distinct territory_code, RIGHT(customer_code,5) customer_code, ship_to_code from #netsales) c
 cross join 
 (select distinct brand, demographic, itemtype from #netsales) b 
 )

-- select * from #netsales where customer_code like '%41407' -- and item_code in ('!','!LENS','M') order by item_code

-- IF(OBJECT_ID('tempdb.dbo.#SSRS_Territory_Planner') is not null) drop table dbo.#SSRS_Territory_Planner

CREATE iNDEX [ns_idx] ON #netsales ([customer_code] ASC, [ship_to_code] ASC )
CREATE iNDEX [ci_idx] ON #custinfo ([customer_code] ASC, [ship_to_code] ASC )


-- Customer /Ship To ONly Sales
select ci.Status
, isnull(rnk.rank,9999) rank
, ci.territory_code, ci.door, ci.Customer_code, ci.ship_to_code
, isnull(ns_summ.column_group,'') column_group
, isnull(ns_summ.column_label,'') column_label
, isnull(ns_summ.cg_special,'') cg_special
, isnull(ns_summ.cl_special,'') cl_special
, isnull(ns_summ.anet_ty,0) anet_ty
, isnull(ns_summ.anet_ly,0) anet_ly
, isnull(ns_summ.areturns_ty,0) areturns_ty
, isnull(ns_summ.rx_ty,0) rx_ty
, ci.address_name, ci.addr2, ci.city, ci.state, ci.postal_code, ci.contact_phone
, ci.tlx_twx, ci.contact_email, ci.contact_name
, Ci.OldestSTOrdDate
, ci.m_address
, ci.m_addr2
, ci.m_city
, ci.m_state
, ci.m_postal_code
, ci.m_contact_phone
, ci.m_tlx_twx
, ci.m_contact_email
, ci.m_contact_name
, ci.m_OldestSTOrdDate
, ci.m_door
, isnull(active_ty.active,0) active
, isnull(active_ly.active,0) active_ly
, isnull(ns_ty,0) ns_ty
, isnull(ns_summ.promo_flg,'') promo_flg

from #custinfo ci 
-- left outer join #netsales ns on ns.Customer_code=ci.Customer_code and ns.ship_to_code=ci.ship_to_code
left outer join
	(select territory_code, customer_code, ship_to_code
	, rank = RANK() OVER (Partition by territory_code order by sum(anet) desc)
	from #netsales
	group by territory_code, customer_code, ship_to_code
) rnk on rnk.customer_code = ci.customer_code and rnk.ship_to_code = ci.ship_to_code

left outer join
(	select ns.customer_code, ns.ship_to_code
-- 10/28/15 - remove CH, add REVO
	, column_group = case when isnull(ns.brand,'') in ('as','bcbg','et','me','revo') then '1 Premium'
						  when isnull(ns.brand,'') in ('dd','fp','di','ko','rr','un','ch') then ''
						  else '2 Core' end
	, column_label = case when isnull(ns.brand,'') not in ('ch','dd','fp','di','ko') then isnull(ns.brand,'')
						  else '' end
	, cg_special = case when isnull(ns.itemtype,'') = 'SUN' then '4 Suns'
						  when isnull(ns.demographic,'') = 'Kids' then '3 Kids'
						  else '' end
	, cl_special = case when isnull(ns.itemtype,'') = 'SUN' then 'Suns'
						  when isnull(ns.brand,'') in ('dd','fp') then 'Pediatric' 
						  when isnull(ns.demographic,'') = 'Kids' then 'Kids'
						  else '' end
	, sum(case when ns.tyly = 'ty' then ns.anet else 0 end) anet_TY
	, sum(case when ns.tyly = 'ly' then ns.anet else 0 end) anet_LY
	, sum(case when ns.tyly = 'ty' then ns.areturns else 0 end) areturns_TY
	, sum(case when ns.tyly = 'ty' and ns.ordertype = 'rx' then  ns.anet else 0 end) RX_TY
	, ns.promo_flg promo_flg
	from #netsales ns
	group BY CASE WHEN ISNULL(ns.brand, '') IN ( 'as', 'bcbg', 'et', 'me', 'revo' )
             THEN '1 Premium'
             WHEN ISNULL(ns.brand, '') IN ( 'dd', 'fp', 'di', 'ko', 'rr', 'un',
             'ch' ) THEN ''
             ELSE '2 Core'
             END ,
             CASE WHEN ISNULL(ns.brand, '') NOT IN ( 'ch', 'dd', 'fp', 'di', 'ko' )
             THEN ISNULL(ns.brand, '')
             ELSE ''
             END ,
             CASE WHEN ISNULL(ns.itemtype, '') = 'SUN' THEN '4 Suns'
             WHEN ISNULL(ns.demographic, '') = 'Kids' THEN '3 Kids'
             ELSE ''
             END ,
             CASE WHEN ISNULL(ns.itemtype, '') = 'SUN' THEN 'Suns'
             WHEN ISNULL(ns.brand, '') IN ( 'dd', 'fp' ) THEN 'Pediatric'
             WHEN ISNULL(ns.demographic, '') = 'Kids' THEN 'Kids'
             ELSE ''
             END ,
             ns.customer_code ,
             ns.ship_to_code ,
             ns.promo_flg
) ns_summ on ns_summ.customer_code = ci.customer_code and ns_summ.ship_to_code = ci.ship_to_code
left outer join
(	select ns.customer_code, 1 as active
	from #netsales ns
	where ns.tyly = 'ty'
	group by ns.customer_code
	having sum(anet) >= 2400
) active_ty on active_ty.customer_code = ci.customer_code 
left outer join
(	select ns.customer_code, 1 as active
	from #netsales ns
	where ns.tyly = 'ly'
	group by ns.customer_code
	having sum(anet) >= 2400
) active_ly on active_ly.customer_code = ci.customer_code 
left outer join
(	select ns.customer_code, SUM(ANET) ns_ty
	from #netsales ns
	where ns.tyly = 'ty'
	group by ns.customer_code
) ns_ty on ns_ty.customer_code = ci.customer_code 

End


GO
