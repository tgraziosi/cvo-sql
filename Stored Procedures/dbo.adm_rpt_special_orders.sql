SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_rpt_special_orders] @range varchar(8000) = '0=0',
@ord_status varchar(1000) = '',
@added_sort varchar(100) = '',
@order varchar(1000) = ''
as
set nocount on

select @range = replace(@range,'a.sch_ship_date',' datediff(day,"01/01/1900",sch_ship_date) + 693596 ')
select @range = replace(@range,'a.date_shipped ',' datediff(day,"01/01/1900",date_shipped) + 693596 ')
select @range = replace(@range,'"','''')
select @ord_status = replace(@ord_status,'"','''')
select @order = replace(@order,'"','''')

create table #oap_links (oap_row_id int, oap_status char(1), type char(1),
order_no int, line_no int, ord_ext int, ord_location varchar(10), ord_part varchar(30), ord_row_id int,
ord_complete_perc decimal(20,8), tot_complete_perc decimal(20,8),
rel_po varchar(16), rel_location varchar(10), rel_part varchar(30), rel_row_id int, po_vend varchar(12),
)

insert #oap_links
select oap.row_id, oap.status, 'R',
oap.order_no, oap.line_no, 0, '','',0,0,0,
isnull(r.po_no,''), isnull(r.location,''), isnull(r.part_no,''),isnull(r.row_id,0),''
from orders_auto_po oap
left outer join releases r on r.po_no = oap.po_no and r.ord_line = oap.line_no

insert #oap_links
select isnull(oap.oap_row_id,0),isnull(oap.oap_status,''), 'O',
l.order_no, l.line_no, l.order_ext, l.location, l.part_no, l.row_id,
case when l.status > 'R' or ordered = 0 then 1 else shipped/ordered end,0,
isnull(oap.rel_po,''), isnull(oap.rel_location,''), isnull(oap.rel_part,''), isnull(oap.rel_row_id,0),''
from ord_list l
left outer join #oap_links oap on oap.order_no = l.order_no and oap.line_no = l.line_no
where l.status != 'L' and (create_po_flag = 1 or l.location like 'DROP%')
and (ordered <> 0 or shipped <> 0)

delete from #oap_links
where type = 'R'

update a
set po_vend = p.vendor_no
from #oap_links a, purchase_all p
where a.rel_po = p.po_no

update a
set tot_complete_perc = 
isnull((select sum(ord_complete_perc)/count(ord_complete_perc)
from #oap_links l
where l.order_no = a.order_no and l.ord_ext = a.ord_ext),0)
from #oap_links a

declare @sql varchar(8000)
select @sql = 'select distinct 
a.order_no, a.ord_ext, a.line_no, a.ord_part, a.ord_location,
a.ord_complete_perc * 100,a.tot_complete_perc * 100,
o.cust_code, c.customer_name, case o.status when ''M'' then ''Y'' else ''N'' end,
ol.description, ol.ordered, ol.shipped, ol.status, o.sch_ship_date, o.date_shipped,ol.uom,
a.rel_po, re.po_line, re.release_date, a.rel_location, a.rel_part,
re.quantity, re.received, re.status,
a.po_vend, v.vendor_name
from #oap_links a (nolock)
join ord_list ol (nolock) on ol.row_id = a.ord_row_id and ol.order_no = a.order_no
join orders_all o (nolock) on o.order_no = a.order_no and o.ext = a.ord_ext
join adm_cust_all c (nolock) on c.customer_code = o.cust_code
join locations l (nolock) on l.location =  a.ord_location
join region_vw r (nolock) on r.org_id = l.organization_id
left outer join adm_vend_all v (nolock) on v.vendor_code = a.po_vend
left outer join releases re (nolock) on re.row_id = a.rel_row_id and re.po_no = a.rel_po 
where ' + @ord_status + ' and ' + @range +  '
order by ' + @order  + @added_sort + ', a.order_no, a.ord_ext, a.line_no'

exec(@sql)

drop table #oap_links
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_special_orders] TO [public]
GO
