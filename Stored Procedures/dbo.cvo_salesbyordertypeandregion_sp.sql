SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[cvo_salesbyordertypeandregion_sp] @WhereClause varchar(255) as
declare
	@OrderBy	varchar(255),
	@GroupBy	varchar(255)

create table #Summary ( 

Region_Code varchar(10) null,	-- tag 12/14 - for finance 
region	varchar(30) null,
salesconsultant	varchar(30) NULL,

cl_numorders int null,
cl_amtorder decimal(20,8) null,
cl_qtyship decimal(20,8) null,

do_numorders int null,
do_amtorder decimal(20,8) null,
do_qtyship decimal(20,8) null,

rx_numorders int null,
rx_amtorder decimal(20,8) null,
rx_qtyship decimal(20,8) null,

ST_numorders int null,
ST_amtorder decimal(20,8) null,
ST_qtyship decimal(20,8) null,

cr_numorders int null,
cr_amtorder decimal(20,8) null,
cr_qtyship decimal(20,8) null,


other_numorders int null,
other_amtorder decimal(20,8) null,
other_qtyship decimal(20,8) null,

x_InvoiceDate datetime default getdate()

)

select @OrderBy = ' order by region_code asc, region ASC, salesconsultant asc '
select @Groupby = ' group by region_code, region, salesconsultant '

exec (' insert #Summary select 
region_code,
region,
salesconsultant,
sum(num_orders_cl),
sum(amt_order_cl),
sum(qty_ship_cl),
sum(num_orders_do),
sum(amt_order_do),
sum(qty_ship_do),
sum(num_orders_rx),
sum(amt_order_rx),
sum(qty_ship_rx),
sum(num_orders_st),
sum(amt_order_st),
sum(qty_ship_st),
sum(num_orders_cr),
sum(amt_order_cr),
sum(qty_ship_cr),
sum(num_orders_other),
sum(amt_order_other),
sum(qty_ship_other),
getdate()

from cvo_salesbyOrderTypeandRegion_summary_vw ' + @whereclause + @groupBy)

exec (' select * from #Summary ' + @OrderBy)
 


/**/
GO
GRANT EXECUTE ON  [dbo].[cvo_salesbyordertypeandregion_sp] TO [public]
GO
