SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_brandsalestyly_sp]  
@AsOfDateParam datetime,
@Brand varchar(1000),
@Type_Code varchar(1000),
@Territory varchar(1000)

as

-- 042015 - make brand a multi-value list, like territory
-- 071416 - change unit breaks per LM request

declare @fromdateparam datetime, @fromdatelyparam datetime

SELECT @FROMDATEparam = dateadd(yy,-1,dateadd(dd,1,@AsOfDateParam))
SELECT @FROMDATELYparam = dateadd(yy,-2,dateadd(dd,1,@AsOfDateParam))

-- exec cvo_brandsalestyly_sp '6/30/2014','bcbg','frame,sun',20201

/*
set @asofdateparam = '6/30/2014'
set @brand = 'bcbg'
set @type_code = 'frame,sun'
*/

CREATE TABLE #restype ([restype] VARCHAR(10))
INSERT INTO #restype ([restype])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@Type_code)

CREATE TABLE #terr ([terr] VARCHAR(10))
INSERT INTO #terr ([terr])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@Territory)

CREATE TABLE #brand ([brand] VARCHAR(10))
INSERT INTO #brand ([brand])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@brand)

;with cte as 
(select sbm.customer Customer_Code, 
case when yyyymmdd < @FromDateParam then 'LY' else 'TY' end as YR,
sum (anet) [Net Amount], sum (qnet) [Net Quantity] ,
sum (qsales) qsales,
sum (case when return_code ='' then qreturns else 0 end) ra_qty,
sum (case when return_code ='wty' then qreturns else 0 end ) wty_qty
from cvo_sbm_details sbm 
join armaster ar on sbm.customer = ar.customer_code and ar.ship_to_code = sbm.ship_to
join inv_master i on i.part_no = sbm.part_no
join #restype r on i.type_code = r.restype
join #terr t on ar.territory_code = t.terr
join #brand b on i.category = b.brand
where yyyymmdd between @FromDateLYParam and @AsOfDateParam
-- and i.category = @Brand
group by sbm.customer, case when yyyymmdd < @FromDateParam then 'LY' else 'TY' end
)
select cte.Customer_Code, [Net Amount], [Net Quantity], qsales, ra_qty, wty_qty, YR, 
SizeSales = case when [net amount] is null then null
		when [Net Amount] <= 0 then '$0 or Less'
		when [Net Amount] < 500 then '$1 - $499'
		when [Net Amount] < 1000 then '$500 - $999'
		when [Net Amount] < 2500 then '$1000 - $2499'
		when [Net Amount] < 3300 then '$2500 - $3299'
		when [Net Amount] < 5000 then '$3300 - $4999'
		else '$5000 or more'
		end
,SizeSales_sort = case when [Net Amount] is null then null
		when [Net Amount] <= 0 then 1
		when [Net Amount] < 500 then 2
		when [Net Amount] < 1000 then 3
		when [Net Amount] < 2500 then 4
		when [Net Amount] < 3300 then 5
		when [Net Amount] < 5000 then 6
		else 7
		end
--,SizeQty = case when [net quantity] is null then null
--		when [Net Quantity] <= 0 then '0 or Less'
--		when [Net Quantity] < 12 then '1 - 12'
--		when [Net Quantity] < 25 then '13 - 24'
--		when [Net Quantity] < 50 then '25 - 49'
--		when [Net Quantity] < 75 then '50 - 74'
--		when [Net Quantity] < 100 then '75 - 99'
--		else '100 or more'
--		end
--,SizeQty_sort = case when [Net Quantity] is null then null
--		when [Net Quantity] <= 0 then 1
--		when [Net Quantity] < 12 then 2
--		when [Net Quantity] < 25 then 3
--		when [Net Quantity] < 50 then 4
--		when [Net Quantity] < 75 then 5
--		when [Net Quantity] < 100 then 6
--		else 7
--		end 

,SizeQty = case when [net quantity] is null then null
		when [Net Quantity] <= 0 then '0 or Less'
		when [Net Quantity] < 15 then '1 - 15'
		when [Net Quantity] < 29 then '16 - 29'
		when [Net Quantity] < 49 then '30 - 49'
		when [Net Quantity] < 74 then '50 - 74'
		when [Net Quantity] < 99 then '75 - 99'
		else '100 or more'
		end
,SizeQty_sort = case when [Net Quantity] is null then null
		when [Net Quantity] <= 0 then 1
		when [Net Quantity] < 15 THEN 2
		when [Net Quantity] < 29 then 3
		when [Net Quantity] < 49 then 4
		when [Net Quantity] < 74 then 5
		when [Net Quantity] < 99 then 6
		else 7
		end 
FROM cte


GO
GRANT EXECUTE ON  [dbo].[cvo_brandsalestyly_sp] TO [public]
GO
