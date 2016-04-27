SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
exec cvo_cir
select distinct territory, cust_code from cvo_carbi 
--where cust_code = '023806'
--where ship_to <> ''
--where address_name like '%brilliant%'
-- where cust_code = '046759' and territory = '50506'
where address_name is null
custnetsales <> totacctnetsales

SELECT * FROM CVO_CARBI WHERE STYLE = 'WOODIE WAGON'

select * From cvo_carbi where cust_code = '044057'
select territory_code, * From armaster where customer_code = '044057'

*/

CREATE PROCEDURE [dbo].[CVO_CIR]  
AS

SET NOCOUNT ON

DECLARE @first datetime                                    
DECLARE @last datetime                                                           
DECLARE @F12 datetime
declare @L12 datetime 
Declare @F36 datetime 
declare @f24 datetime --v3.3
declare @LYstart datetime
declare @TYstart datetime
declare @pom_asof datetime

/**
	3/12/2012 - TAG - Rewrite                    
	v3.1 - 4/26/2012 - April Release
	color description, show 36 month window of sales
	 fix join to artrx to use orders_invoice instead of order_ctrl_num
	 add last stock order date to table
    v3.2 - 5/31/2012 - May Changes
	POM indicator
	Net Sales for the reporting period - 12 months
	v3.3 - 6/21/2012 - June Changes
			exclude rebills
			add more sales figures - p12, ytd ty and ly
			last stock order date and order number
	v3.4 - updates for ssrs - add city and postal code - 072512
	v4.0 - July release - collapse affiliated accounts to the active account
		   where the from account is not active
	v4.1 - august - add POM status (RYG)
	v4.2 - Sept - add short_name for sorting and updates for pom active flag
	v4.3 - Nov 2012 - add unposted AR - arinpchg
	v4.4 - Dec 2012 - for last st order, only consider orders, not credits
			include Net sales for entire account too.
	v5.0 - Jan 2013 - run at any date - rewrite - again
	v5.1 - collapse inactive ship-tos to main account
	v5.2 - correct summary sales figures on collapsed ship-tos, and # on partial pom styles
    v5.3 - check for territory match when rolling up non-door accounts and change the way the address is 
           maintained so that the correct address displays with non-door ship-to's
**/

/** Run Times: 10/4/2012 - 16:04 **/
/** 2/20/2013 - 8 min - db-02 **/
/** 2/25 4:44m - db03 */
/** 11/19/13 4:24 */
/** 01/23/14 05:05 */
/** 08/21/14 04:03 */
/** 9/25/2015 03:26 after index on carbi table */


-- get the first and last day of this month                                 
--SET @first=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(getdate())-1),getdate()),101))      
SET @first=(SELECT CONVERT(VARCHAR(25),getdate(),101)) -- today       
set @pom_asof = @first

-- UNCOMMENT FOR THE PRINTED CIR RUN
-- set @pom_asof = '4/26/2016'
          
-- set @first = '08/28/2013'
                  
--set @first = '6/1/2012'
--SET @first=dateadd(mm,-2,@first)    
--set @first = dateadd(mm,-1,@first)  --First Day of previous month
--set @last = dateadd(dd,-1,@first)   --Last Day of previous month        
set @last =   (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-1,getdate()),101)+' 23:59' )  -- yesterday
-- SET @last=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,getdate()))),DATEADD(mm,1,getdate())),101)) -- last day of this month
--set @last = '03/27/2013 23:59'


--select @first, @last
                        
SET @f12=dateadd(m,-12,@first)
set @f36=dateadd(m,-36,@first)
set @f24=dateadd(m,-24,@first) -- v3.3                                                
SET @l12=dateadd(d,-1,@first)

set @lystart = '1/1/' + cast(year(@f12) as varchar(4))
set @tystart = '1/1/' + cast(year(@last) as varchar(4))    

declare @Jf12 int, @jf36 int, @jlast int

select @Jf12 = dbo.adm_get_pltdate_f( @f12 )
select @Jf36 = dbo.adm_get_pltdate_f( @f36 )
select @Jlast = dbo.adm_get_pltdate_f( @last )

select @last, @jlast

select 'f36= ',@f36,' f24= ',@f24

select '12mty=', @f12, @last
select '12mly=', @f24, dateadd(yy,-1,@last)
select 'ytdty=', datepart(yy,@first), datepart(m,@last)
select 'ytdly=', datepart(yy,dateadd(yy,-1,@first)), datepart(m,@last)

-- get part info
print 'starting part_info'
select getdate()
 
if(object_id('tempdb.dbo.#tgCategorystyleEyeSizes') is not null)
drop table #tgCategorystyleEyeSizes
if(object_id('tempdb.dbo.#tgSumEyeSizes') is not null)
drop table #tgSumEyeSizes
if(object_id('tempdb.dbo.#p') is not null)
drop table #p
if(object_id('tempdb.dbo.#pp') is not null)
drop table #pp


select distinct CATEGORY, field_2, (convert(varchar,(convert(int,isnull(field_17,0))))) eye_size
into #tgCategoryStyleEyeSizes	
from inv_master_add a, inv_master b where field_17<>0
	AND a.part_no = b.part_no and b.type_code in ('FRAME','SUN')

CREATE NONCLUSTERED INDEX [idx_for_eyesizes] ON #tgcategorystyleeyesizes 
(	[category] asc, [field_2] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

-- select * from #categoryStyleEyeSizes

select distinct CATEGORY, field_2, 
        STUFF ( ( SELECT ' ' + EYE_SIZE FROM
		#tgcategoryStyleEyeSizes a
		where a.category = c.category and a.field_2 = c.field_2
		FOR XML PATH ('') ), 1, 1, '' ) AS EyeSizes
into #tgSumEyeSizes
from #tgcategoryStyleEyeSizes c

CREATE NONCLUSTERED INDEX [idx_for_eyesizes] ON #tgsumeyesizes
(	[category] asc, [field_2] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

select b.part_no, c.category, b.field_2 style, b.field_3 color_desc, 
  case when b.field_28 > @pom_asof then '' else isnull(b.field_28,'') end as POM_date,
  c.obsolete, 
  dbo.f_cvo_get_pom_tl_status(c.category, b.field_2, b.field_3, @pom_asof /*@first*/) RYG
into #p
From inv_master c (nolock) 
inner join inv_master_add  b (nolock) on c.part_no = b.part_no
where c.type_code in ('frame','sun')

--select * from #p where style = 'tilden park'

IF(OBJECT_ID('tempdb.dbo.#part_info') is not null)  
drop table #part_info

--select   dbo.f_cvo_get_pom_tl_status('JC', 'TILDEN PARK','BERRY','12/24/2013' /*@first*/) 

--SELECT * FROM CVO_POM_TL_STATUS WHERE ACTIVE = 1 AND STYLE = 'TILDEN PARK'
--ORDER BY STYLE
 

select
p.part_no,
p.style,
p.category,
CASE
-- v4.1	
	When p.color_desc is null then 
		  p.style + ' ' + p.part_no -- color description v3.1
	when p.pom_date <= @pom_asof and p.pom_date <> '1/1/1900' and p.ryg <> 'x' -- @last 
	 	 then '#' + p.ryg + ' ' + p.style + ' ' + p.color_desc + ' ' +
		 isnull((select eyesizes from #tgsumeyesizes a
		 where a.category = p.category and a.field_2 = p.style),'' )
	else   -- color/active
		p.style + ' ' + p.color_desc +  ' ' + 
		isnull((select eyesizes from #tgsumeyesizes a
		where a.category = p.category and a.field_2 = p.style),'' )
	end as part_no2 ,
p.POM_date,
p.obsolete
Into #part_info  
From #p p

create clustered index [idx_part_no] on #part_info (part_no)

-- Buying Group info
-- 071712 - tag - fix buying group

IF(OBJECT_ID('tempdb.dbo.#bg') is not null)  
drop table #bg

select ar.customer_code, ar.price_code discount, 
			 CASE When b.parent is null Then 'Direct Billing'
			 when b.parent between '000500' and '000699' 
				 then 'Buying Group: ' + 
				 (select top 1 customer_name  from arcust where
					customer_code = b.parent)
			 Else 'Bill-To: ' + ar.customer_name 
		End as buying
Into #bg  
FROM arcust ar (nolock) 
left outer join ARNAREL B (NOLOCK) ON ar.customer_code = B.CHILD

--
IF(OBJECT_ID('tempdb.dbo.#cust_info') is not null)  
drop table #cust_info

select distinct
b.customer_code cust_code,
b.ship_to_code ship_to,
---- v5.3
--case when b.status_type <> 1 and b.ship_to_code <> '' then ''
--    else isnull(b.ship_to_code,'') end as ship_to, 
---- v5.3
b.address_name, 
b.addr2, b.addr3, b.addr4,
b.contact_phone,
b.city, b.postal_code,
REPLACE(b.short_name,'D-','D ') customer_short_name, -- 10/3/12 - v4.2 - Dr name sort
'Date Opened ' + SUBSTRING(CAST((CAST(FLOOR(CAST(b.added_by_date AS float )) AS DATETIME)) as varchar), 1, 11) date_opened,
b.territory_code territory -- v5.3 082813 - tag
into #cust_info
from armaster b (nolock)

create index idx_cust_info_1 on #cust_info (territory, cust_code, ship_to)

--select * From #cust_info where cust_code = '023806'
  
IF(OBJECT_ID('tempdb.dbo.#vsordList') is not null)  
drop table #vsordList  

Select 
-- v3.2, v3.3 - exclude rebills
Shipped = case when t2.type = 'i' and t2.user_category not like '%RB' -- right(t2.user_category,2) <> 'RB' 
					then isnull(t1.shipped,0)
		       when t2.type = 'c' and t1.return_code not like '05%' -- left(t1.return_code,2) <> '05' 
					then isnull(t1.cr_shipped,0)*-1
			   else 0
		  end,
--v3.1
TimeEntered = case when t2.type = 'I' then t1.time_entered end,
t2.type, 
t2.user_category, 
t2.cust_code, 
-- tag 082913 v5.3
case when ar.status_type <> 1 and ar.ship_to_code <> '' then ''
    else isnull(ar.ship_to_code,'') end as ship_to, 
-- v5.3 
ar.territory_code territory,
t1.part_no, 
t5.date_applied,
convert(varchar,dateadd(d,t5.DATE_APPLIED-711858,'1/1/1950'),101) as ShipDate, 
convert(varchar,t2.order_no) as order_no,  --v3.3 -- make varchar to match with history 
t2.ext

Into #vsordList 

From orders_all t2 (nolock) 
inner join orders_invoice oi (nolock) on t2.order_no = oi.order_no and t2.ext = oi.order_ext
inner join artrx t5 (nolock) on 
	oi.trx_ctrl_num = t5.trx_ctrl_num 
--v3.1
	and t5.trx_type in (2031,2032) and t5.void_flag = 0  
	and t5.doc_desc not like 'CONVERTED%' AND T5.DOC_DESC NOT LIKE '%NONSALES%'
	AND T5.DOC_CTRL_NUM NOT LIKE 'CB%' AND T5.DOC_CTRL_NUM NOT LIKE 'FIN%'
inner join ord_list t1(nolock) on t1.order_no = t2.order_no  and t1.order_ext = t2.ext 
inner join inv_master t4 (nolock) on t4.part_no = t1.part_no  
left outer join armaster ar (nolock) on t2.cust_code = ar.customer_code and t2.ship_to = ar.ship_to_code 

--left outer join armaster b (nolock) on b.customer_code = t2.cust_code and b.ship_to_code = t2.ship_to
Where t5.date_applied between @jf36 and @jlast 
and t4.type_code in ('FRAME','SUN')
and t2.status = 'T' 
--and (t1.shipped > 0 or t1.cr_shipped>0)
--and t4.obsolete = 0		-- active items only                  

--v3.1

print 'Done with ord_list - posted invoices'
select getdate()

Insert Into #vsordList 
Select 
-- v3.2, v3.3 - exclude rebills
Shipped = case when t2.type = 'i' and t2.user_category not like '%RB' -- right(t2.user_category,2) <> 'RB' 
					then isnull(t1.shipped,0)
		       when t2.type = 'c' and t1.return_code not like '05%' -- left(t1.return_code,2) <> '05' 
					then isnull(t1.cr_shipped,0)*-1
			   else 0
		  end,
--v3.1
TimeEntered = case when t2.type = 'I' then t1.time_entered end,
--t1.time_entered,
--v3.1
t2.type, 
t2.user_category, 
t2.cust_code, 
-- tag 082913 v5.3
case when ar.status_type <> 1 and ar.ship_to_code <> '' then ''
    else isnull(ar.ship_to_code,'') end as ship_to, 
-- isnull(t2.ship_to,'') ship_to, 
ar.territory_code territory,
t1.part_no, 
t5.date_applied,
convert(varchar,dateadd(d,t5.DATE_APPLIED-711858,'1/1/1950'),101) as ShipDate, 
convert(varchar,t2.order_no) as order_no,  --v3.3 -- make varchar to match with history 
t2.ext

From orders_all t2 (nolock)
inner join orders_invoice oi (nolock) on t2.order_no = oi.order_no and t2.ext = oi.order_ext
inner join arinpchg t5 (nolock) on 	oi.trx_ctrl_num = t5.trx_ctrl_num 
inner join ord_list t1(nolock)  on t1.order_no = t2.order_no  and t1.order_ext = t2.ext            
inner join inv_master t4 (nolock) on t4.part_no = t1.part_no 
left outer join armaster ar (nolock) on t2.cust_code = ar.customer_code and t2.ship_to = ar.ship_to_code 


Where t5.date_applied between @jf36 and @jlast 
--v3.1
	and t5.trx_type in (2031,2032) -- and t5.void_flag = 0  
	and t5.doc_desc not like 'CONVERTED%' AND T5.DOC_DESC NOT LIKE '%NONSALES%'
	AND T5.DOC_CTRL_NUM NOT LIKE 'CB%' AND T5.DOC_CTRL_NUM NOT LIKE 'FIN%'
and t4.type_code in ('FRAME','SUN')
and t2.status = 'T'  
and (t1.shipped > 0 or t1.cr_shipped>0)
--and t4.obsolete = 0		-- active items only

union all

Select 
shipped= isnull(t1.shipped,0) - isnull(t1.cr_shipped,0),
--v3.1
TimeEntered = case when t2.type = 'I' then t1.time_entered end,
--t1.time_entered,
--v3.1
t2.type, 
t2.user_category, 
t2.cust_code, 
-- tag 082913 v5.3
case when ar.status_type <> 1 and ar.ship_to_code <> '' then ''
    else isnull(ar.ship_to_code,'') end as ship_to, 
-- v5.3
ar.territory_code territory,
t1.part_no, 
(datediff(day,'1/1/1950',convert(datetime,
  convert(varchar( 8), (year(t2.date_shipped) * 10000) 
  + (month(t2.date_shipped) * 100) + day(t2.date_shipped)))  ) + 711858),
t2.date_shipped,
t2.user_def_fld4 as order_no,  -- v3.3
--t2.order_no,
t2.ext

From cvo_orders_all_hist t2 (nolock)  
inner join cvo_ord_list_hist t1 (nolock) on t2.order_no = t1.order_no and t2.ext = t1.order_ext    
inner join inv_master t4 (nolock) on t4.part_no = t1.part_no
left outer join armaster ar (nolock) on t2.cust_code = ar.customer_code and t2.ship_to = ar.ship_to_code 
Where t2.date_shipped between @f36 and @last 
and t4.type_code in ('FRAME','SUN')  
and t2.status = 'T'
--and t4.obsolete = 0		-- active items only

print 'Done with ord_list hist'

CREATE NONCLUSTERED INDEX [idx_vsord_custno] ON #vsordlist 
(	[territory] asc,
    [cust_code] ASC,
	[ship_to] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

-- fix global ship-to's and other oddities in history table

delete from #vsordlist where shipped = 0

UPDATE a SET SHIP_TO='' 
--select * 
FROM #vsordlist a
where not exists(select * from  ARMASTER AR where a.CUST_CODE=AR.CUSTOMER_CODE AND a.SHIP_TO=ar.SHIP_TO_CODE)

-- v5.3 - don't need to do this here any longer

-- Collapse ship-to's that are not active
--update a set ship_to = ''
--from cvo_armaster_all ca (nolock) inner join #vsordlist a
--on ca.customer_code = a.cust_code and ca.ship_to =a.ship_to
--where ca.ship_to <> '' and ca.door = 0


--update a set ship_to = ''
--from armaster ca (nolock) inner join #vsordlist a
--on ca.customer_code = a.cust_code and ca.ship_to_code =a.ship_to
--where ca.status_type <> 1 and ship_to <> ''

-- get date and order number of most recent stock order
IF(OBJECT_ID('tempdb.dbo.#last_st') is not null)  
	drop table #last_st
create index idx_ord on #vsordlist (territory, cust_code, ship_to, 
	user_category, type, timeentered, order_no)
	
select cust_code , ship_to , max(timeentered) last_st_ord_date,	
	'0000000000' as last_st_order_no
	, territory -- 082813
	into #last_st
	from #vsordlist (nolock) v
	where ext = 0 and left(user_category,2) = 'ST' and type = 'i' 
	group by territory, cust_code, ship_To
create index idx_ls on #last_st (territory, cust_code, ship_to,  last_st_ord_date)

--tempdb..sp_help #last_st
--tempdb..sp_help #vsordlist

update ls set last_st_order_no = LEFT(v.order_no,10)
	from #last_st ls inner join #vsordlist v on ls.cust_code = v.cust_code and ls.ship_to = ls.ship_to
	    and ls.territory = v.territory
	where ls.last_st_ord_date = v.timeentered and v.ext = 0 
	and v.user_category like 'ST%' 
	-- left(v.user_category,2) = 'ST' 
	and v.type = 'i' 

--select * from #last_st
         
-- v5.2 - Setup summary figures

IF(OBJECT_ID('tempdb.dbo.#cs') is not null)  
	drop table #cs
select ar.territory_code, cs.customer,
case when ar.status_type <> 1 and cs.ship_to<> '' then '' else cs.ship_to end as ship_to,
sum(case when yyyymmdd between @f12 and @last then anet else 0 end)  as Custnetsales,
sum(case when yyyymmdd between @f24 and dateadd(yy,-1,@last) then anet else 0 end) as NetSalesLY,
sum(case when yyyymmdd between @tystart and @last then anet else 0 end) as YTDTY,
sum(case when yyyymmdd between @lystart and dateadd(yy,-1,@last) then anet else 0 end) as YTDLY

--sum(case when [year] = datepart(yy,@first) and [x_month] <= month(@last) then anet else 0 end) as YTDTY,
--sum(case when [year] = datepart(yy,dateadd(yy,-1,@first)) and [x_month] <= month(@last) then anet else 0 end) as YTDLY
into #cs
-- from cvo_csbm_shipto cs (nolock)
-- from cvo_csbm_shipto_daily cs (nolock)
FROM dbo.cvo_sbm_details AS cs (nolock)
inner join armaster ar (nolock) on cs.customer = ar.customer_code and cs.ship_to = ar.ship_to_code
where yyyymmdd between @f24 and @last
group by ar.territory_code, cs.customer,
case when ar.status_type <> 1 and cs.ship_to<> '' then '' else cs.ship_to end

create index idx_cs on #cs (territory_code, customer, ship_to)

-- 
print 'Start cvo_CIR'
select getdate()

IF(OBJECT_ID('tempdb.dbo.#cvo_CIR_det') is not null)  
drop table #cvo_CIR_det  

declare @MinNetSales decimal(20,8)
set @minNetSales = 1

Select 
a.territory, 
a.cust_code, 
a.ship_to, 
a.part_no,
A.timeentered,
-- v5.2
isnull(#cs.custnetsales, 0) custnetsales,
isnull(#cs.netsalesly, 0) netsalesly,
isnull(#cs.ytdty, 0) ytdty,
isnull(#cs.ytdly, 0) ytdly,
/*
Custnetsales = isnull((select sum(anet) from cvo_csbm_shipto where
	   customer = a.cust_code and ship_to=a.ship_to and yyyymmdd 
	   between @f12 and @last), 0),
--v3.3 
NetSalesLY = isnull(( select sum(anet) from cvo_csbm_shipto where
		customer = a.cust_code and ship_to=a.ship_to and yyyymmdd 
		between @f24 and dateadd(yy,-1,@last)), 0),
YTDTY = isnull(( select sum(anet) from cvo_csbm_shipto where
		customer = a.cust_code and ship_to=a.ship_to and 
		[year] = datepart(yy,@first) and [x_month] <= month(@last), 0),
YTDLY = isnull(( select sum(anet) from cvo_csbm_shipto where
		customer = a.cust_code and ship_to=a.ship_to and 
		[year] = datepart(yy,dateadd(yy,-1,@first)) and [x_month] <= month(@last), 0),
*/
ST12 = case when (A.ShipDate >= @f12 and A.type = 'I' and a.user_category like 'ST%')
	--left(A.user_category,2) = 'ST') 
	then (a.shipped) else 0 end,
ST36 = case when (A.type = 'I' and a.user_category like 'ST%')
	--left(A.user_category,2) = 'ST') 
	then (a.shipped) else 0 end,
RX12 = case when (A.ShipDate >= @f12 and A.type = 'I' and a.user_category like 'RX%')
	--left(A.user_category,2) = 'RX') 
	then (a.shipped) else 0 end,
RX36 = case when (A.type = 'I' and a.user_category like 'RX%')
	--left(A.user_category,2) = 'RX') 
	then (a.shipped) else 0 end,
RET12 = case when (A.ShipDate >= @f12 and A.type = 'C') then (a.shipped) else 0 end,
RET36 = case when A.type = 'C' then (a.shipped) else 0 end,
NET12 = CASE WHEN (A.ShipDate >= @f12) 
		and (left(a.user_category,2) in ('RX','ST') or a.type='c') then (a.shipped) else 0  end,
net36 = case when (left(a.user_category,2) in ('RX','ST') or a.type='c') then a.shipped else 0 end,
OTH12 = case when (A.ShipDate >= @f12 and A.type = 'I' and left(a.user_category,2) not in ('RX','ST')) then (a.shipped) else 0 end,
OTH36 = case when (A.type = 'I' and left(a.user_category,2) not in ('RX','ST')) then (a.shipped) else 0 end,
-- v4.4
TotAcctNetSales =  isnull((select sum(anet) from cvo_csbm_shipto_daily cs, armaster ar 
where cs.customer = ar.customer_code and cs.ship_to = ar.ship_to_code
	  and cs.customer = a.cust_code 
	  and ar.territory_code = a.territory
	  and cs.yyyymmdd between @f12 and @last), 0)

Into #cvo_CIR_det
from #vsordlist a (nolock)
left outer join #cs (nolock) on a.territory = #cs.territory_code and a.cust_code = #cs.customer and a.ship_to = #cs.ship_to

-- end v5.2

CREATE NONCLUSTERED INDEX [idx_cvo_CIR] ON #cvo_CIR_det 
(
	[territory] ASC,
	[cust_code] ASC,
	[ship_to] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

/* 080112 - tag -  new code to combine affiliated accounts */
--select * from #cvo_cir_det where cust_code in ('931867','031867')

IF(OBJECT_ID('tempdb.dbo.#cust_swap') is not null)  
drop table #cust_swap  

select a.customer_code as from_cust, a.ship_to_code as shipto, 
a.affiliated_cust_code as to_cust,
a.territory_code as territory
into #cust_swap
from armaster a (nolock) inner join
armaster b (nolock) on a.affiliated_cust_code = b.customer_code and a.ship_to_code = b.ship_to_code
where a.status_type <> 1 and a.address_type <> 9 
and a.affiliated_cust_code<> '' and a.affiliated_cust_code is not null
and b.status_type = 1 and b.address_type <> 9
and (a.customer_code like '9%' or b.customer_code like '9%')
--(left(a.customer_code,1)= '9' or left(b.customer_code,1) = '9')

select @@rowcount
select * from #cust_swap

create index idx_cs_1 on #cust_swap (territory, from_cust, shipto, to_cust)

IF(OBJECT_ID('tempdb.dbo.#new') is not null)  
drop table #new

select xx.* 
into #new from #cust_swap c
inner join #cvo_cir_det xx (nolock) on  c.to_cust = xx.cust_code  and c.shipto = xx.ship_to 
    and c.territory = xx.territory

update old
set 
	old.territory = new.territory,
	old.cust_code = new.cust_code,
	old.ship_to = new.ship_to
from
#cust_swap c
inner join #new new on new.cust_code = c.to_cust and c.shipto = new.ship_to and new.territory = c.territory
inner join #cvo_cir_det old (nolock) on old.cust_code = c.from_cust and c.shipto = old.ship_to
    and old.territory = c.territory

update new
set
-- v3.2 - net sales
new.Custnetsales = isnull((select sum(custnetsales) from #cs where
	    #cs.territory_code = c.territory and #cs.customer in (c.to_cust,c.from_cust) and #cs.ship_to=c.shipto), 0),
--v3.3 
new.NetSalesLY = isnull(( select sum(netsalesly) from #cs where
		#cs.territory_code = c.territory and #cs.customer in (c.to_cust,c.from_cust) and #cs.ship_to=c.shipto), 0),
new.YTDTY = isnull(( select sum(ytdty) from #cs where
		#cs.territory_code = c.territory and (#cs.customer = c.to_cust or #cs.customer = c.from_cust) and #cs.ship_to=c.shipto), 0),
new.YTDLY = isnull(( select sum(ytdly) from #cs where
		#cs.territory_code = c.territory and (#cs.customer = c.to_cust or #cs.customer = c.from_cust) and #cs.ship_to=c.shipto), 0), 
new.TotAcctNetSales =  isnull((select sum(anet) from 
	cvo_csbm_shipto_daily cs, armaster ar (nolock)
	where cs.customer = ar.customer_code 
	  and cs.customer in (c.to_cust, c.from_cust)
	  and ar.territory_code = c.territory
	  and cs.yyyymmdd between @f12 and @last), 0)
	   
from #cust_swap c
inner join #cvo_cir_det new (nolock) on new.cust_code = c.to_cust and c.shipto = new.ship_to
    and new.territory = c.territory

/* end affiliated update 080112 tag */

IF(OBJECT_ID('dbo.cvo_CarBi') is not null)  drop table dbo.cvo_CarBi

create table dbo.cvo_carbi
(as_of_date datetime,
territory varchar(8),
slp varchar(8),
cust_code varchar(10),
ship_to varchar(10),
address_name varchar(40),
addr2 varchar(40),
addr3 varchar(40),
addr4 varchar(40),
--v3.4
city varchar(40),
postal_code varchar(15),
--
customer_short_name varchar(10), -- v4.2
contact_phone varchar(30),
date_opened varchar(23),
last_st_ord_date datetime,	--v3.1
last_st_order_no varchar(30),
discount varchar(8),
buying varchar(54),
cstatus varchar(26),
custnetsales float, -- v3.2
NetSalesLY float,  -- v3.3
YTDTY float,
YTDLY float,
TotAcctNetSales float, -- v4.4
category varchar(10),
style varchar(40),
part_no2 varchar(100),
pom_date datetime,
First_order_date datetime,
Last_order_date datetime,
mst12 float,
mst36 float,
mrx12 float,
mrx36 float,
mret12 float,
mret36 float,
mnet12 float,
mnet36 float,
moth12 float,
moth36 float
)

CREATE CLUSTERED INDEX [idx_cir_cust] ON cvo_carbi (Cust_code, ship_to)

insert into cvo_carbi
(territory, cust_code, ship_to,
custnetsales, -- v3.2
NetSalesLY,  -- v3.3
YTDTY,
YTDLY,
TotAcctNetSales, -- v4.4
category,
style,
part_no2,
pom_date,
First_order_date ,
Last_order_date ,
mst12 ,
mst36 ,
mrx12 ,
mrx36 ,
mret12 ,
mret36 ,
mnet12 ,
mnet36 ,
moth12 ,
moth36 
)


select 
c.territory,
c.cust_code,
c.ship_to,
c.custnetsales, -- v3.2
c.NetSalesLY,  -- v3.3
c.YTDTY,
c.YTDLY,
c.TotAcctNetSales, -- v4.4
p.category,
p.style,
p.part_no2,
min(p.pom_date)pom_date,
min(c.timeentered) First_order_date,
max(c.timeentered) Last_order_date,
sum(isnull(c.st12,0))mst12,
sum(isnull(c.st36,0))mst36,
sum(isnull(c.rx12,0))mrx12,
sum(isnull(c.rx36,0))mrx36,
sum(isnull(c.ret12,0))mret12,
sum(isnull(c.ret36,0))mret36,
sum(isnull(c.net12,0))mnet12,
sum(isnull(c.net36,0))mnet36,
sum(isnull(c.oth12,0))moth12,
sum(isnull(c.oth36,0))moth36

from #cvo_CIR_det c
inner join #part_info p on c.part_no = p.part_no
group by
territory,
cust_code,
ship_to,
custnetsales, -- v3.2
NetSalesLY,  -- v3.3
YTDTY,
YTDLY,
TotAcctNetSales, -- v4.4
category,
style,
part_no2

-- new

update cir set 
as_of_date = @last,
slp = '',
cir.address_name = b.address_name, 
cir.addr2 = b.addr2, 
cir.addr3 = b.addr3,
cir.addr4 = b.addr4, 
cir.city = b.city,
cir.postal_code = b.postal_code,
cir.customer_short_name = b.customer_short_name, -- v4.2 - 100312
cir.contact_phone = b.contact_phone, 
cir.date_opened = b.date_opened, 
cir.discount = bg.discount, 
cir.buying = bg.buying, 
cir.cstatus = '', 
cir.last_st_ord_date = st.last_st_ord_date,
cir.last_st_order_no = st.last_st_order_no
From cvo_carbi cir 
left outer join #cust_info b on cir.cust_code = b.cust_code and cir.ship_to = b.ship_to
    and cir.territory = b.territory -- 082813
left outer join #bg bg on bg.customer_code = b.cust_code
left outer join #last_st st on cir.cust_code = st.cust_code and cir.ship_to = st.ship_to
    and cir.territory = st.territory -- 082813
-- new 

-- get name and address info for stragglers

update cir set 
as_of_date = @last,
slp = '',
cir.address_name = b.address_name, 
cir.addr2 = b.addr2, 
cir.addr3 = b.addr3,
cir.addr4 = b.addr4, 
cir.city = b.city,
cir.postal_code = b.postal_code,
cir.customer_short_name = b.customer_short_name, -- v4.2 - 100312
cir.contact_phone = b.contact_phone, 
cir.date_opened = b.date_opened, 
cir.discount = bg.discount, 
cir.buying = bg.buying, 
cir.cstatus = '', 
cir.last_st_ord_date = st.last_st_ord_date,
cir.last_st_order_no = st.last_st_order_no
From cvo_carbi cir 
inner join #cust_info b on cir.cust_code = b.cust_code and cir.ship_to = b.ship_to
left outer join #bg bg on bg.customer_code = b.cust_code
left outer join #last_st st on cir.cust_code = st.cust_code and cir.ship_to = st.ship_to
where cir.address_name is null

-- figure date opened on affiliated accounts
update cir set 
cir.date_opened = (select min(date_opened) from #cust_info ci 
where (cs.to_cust = cir.cust_code or cs.from_cust = cir.cust_code)
 and date_opened is not null)
from #cust_swap cs inner join cvo_carbi cir on cs.to_cust = cir.cust_code

--select distinct cust_code, ship_to, custnetsales from cvo_carbi order by cust_code, ship_to

select count(*) from cvo_carbi where (mst12=0 AND mrx12=0 AND mret12=0)
--DELETE FROM CVO_CarBi WHERE (mst12=0 AND mrx12=0 AND mret12=0) -- v3.1 4/26/2012

select count(*) from #cvo_Cir_det
select count(*) from cvo_CarBi

-- 





GO
