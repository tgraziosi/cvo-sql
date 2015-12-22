SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_brandsalestyly_month_sp]  
@AsOfDateParam datetime,
@Brand varchar(1000),
@Type_Code varchar(1000),
@Territory varchar(1000)

as
declare @fromdateparam datetime, @fromdatelyparam datetime

SELECT @FROMDATEparam = dateadd(yy,-1,dateadd(dd,1,@AsOfDateParam))
SELECT @FROMDATELYparam = dateadd(yy,-2,dateadd(dd,1,@AsOfDateParam))

-- exec cvo_brandsalestyly_month_sp '6/30/2014','bcbg','frame,sun'

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
(select year, x_month, 
case when yyyymmdd < @FromDateParam then 'LY' else 'TY' end as YR,
sum (anet) [Net Amount], sum (qnet) [Net Quantity] 
from cvo_sbm_details sbm 
join armaster ar on ar.customer_code = sbm.customer and ar.ship_to_code = sbm.ship_to
join inv_master i on i.part_no = sbm.part_no
join #restype r on i.type_code = r.restype
join #terr t on ar.territory_code = t.terr
join #brand b on i.category = b.brand

where yyyymmdd between @FromDateLYParam and @AsOfDateParam
-- and i.category = @Brand
group by year, x_month, case when yyyymmdd < @FromDateParam then 'LY' else 'TY' end
)
select [Net Amount], [Net Quantity],
year, x_month,
CASE WHEN X_MONTH <= MONTH(@ASOFDATEPARAM) 
			THEN X_MONTH-MONTH(@ASOFDATEPARAM)+12
			ELSE X_MONTH-MONTH(@ASOFDATEPARAM)
			END AS SORT_MONTH,
YR, 
SizeSales = case when isnull([Net Amount],0)=0 then null
		when [Net Amount] <= 0 then right(space(15)+'$0 or Less',15)
		when [Net Amount] < 500 then right(space(15)+'$1 - $499',15)
		when [Net Amount] < 1000 then right(space(15)+'$500 - $999',15)
		when [Net Amount] < 2500 then right(space(15)+'$1000 - $2499',15)
		when [Net Amount] < 3300 then right(space(15)+'$2500 - $3299',15)
		when [Net Amount] < 3300 then right(space(15)+'$3300 - $4999',15)
		else right(space(15)+'$5000 or more',15)
		end
,SizeQty = case when isnull([Net Quantity],0)=0 then null
		when [Net Quantity] <= 0 then right(space(15)+'0 or Less',15)
		when [Net Quantity] < 12 then right(space(15)+'1 - 12',15)
		when [Net Quantity] < 25 then right(space(15)+'13 - 24',15)
		when [Net Quantity] < 50 then right(space(15)+'25 - 49',15)
		when [Net Quantity] < 75 then right(space(15)+'50 - 74',15)
		when [Net Quantity] < 100 then right(space(15)+'75 - 99',15)
		else right(space(15)+'100 or more',15)
		end
from cte

GO
GRANT EXECUTE ON  [dbo].[cvo_brandsalestyly_month_sp] TO [public]
GO
