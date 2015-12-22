SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_bol] @bol varchar(16)
as
begin
declare @home_curr varchar(10)

select @home_curr = home_currency from glco

create table #rpt_bol(
	b_bl_no int NULL, b_bl_type char(1) NULL, b_bl_src_no int NULL, b_bl_src_ext int NULL,
	b_bill_to_code varchar(10) NULL, b_bill_to_name varchar(40) NULL, b_bill_to_add_1 varchar(40) NULL,
	b_bill_to_add_2 varchar(40) NULL, b_bill_to_city varchar(40) NULL, b_bill_to_state varchar(40) NULL,
	b_bill_to_zip varchar(10) NULL, b_location varchar(10) NULL, b_routing varchar(10) NULL,
	b_routing_desc varchar(20) NULL, b_no_packages int NULL, b_cod_amount decimal(20,8) NULL, b_date_shipped datetime NULL,
	b_po_no varchar(20) NULL, b_skids int NULL, b_ship_to_region varchar(10) NULL, b_tare_wt decimal(20,8) NULL,
	b_freight_type varchar(10) NULL, b_who_entered varchar(20) NULL, b_date_entered datetime NULL,
	b_void char(1) NULL, b_void_who varchar(20) NULL, b_void_date datetime NULL, b_ship_to_note varchar(255) NULL,
	b_notes varchar(255) NULL,
	l_bl_no int NULL, l_order_no int NULL, l_order_ext int NULL, l_line_no int NULL, l_location varchar(10) NULL,
	l_freight_class varchar(10) NULL, l_description varchar(255) NULL, l_time_entered datetime NULL,
	l_shipped decimal(20,8) NULL, l_note varchar(255) NULL, l_note_flag char(1) NULL, l_who_entered varchar(20) NULL,
	l_uom char(2) NULL, l_misc varchar(20) NULL, l_weight decimal(20,8) NULL, l_dot varchar(255) NULL, l_hm char(1) NULL,
	l_uom2 char(2) NULL, l_shipped2 decimal(20,8) NULL, l_bl_type char(1) NULL, l_part_no varchar(30) NULL,
	l_po_no varchar(20) NULL, l_conv_factor decimal(20,8) NULL, l_conv_factor2 decimal(20,8) NULL,
	lo_name varchar(30) NULL,
	lo_addr1 varchar(40) NULL, lo_addr2 varchar(40) NULL, lo_addr3 varchar(40) NULL,
	lo_addr4 varchar(40) NULL, lo_addr5 varchar(40),
	b_currency_code varchar(10)
)

exec('insert #rpt_bol
SELECT b.bl_no, b.bl_type, b.bl_src_no, b.bl_src_ext, b.bill_to_code, b.bill_to_name,
b.bill_to_add_1, b.bill_to_add_2, b.bill_to_city, b.bill_to_state, b.bill_to_zip, b.location,
b.routing, b.routing_desc, b.no_packages, b.cod_amount, b.date_shipped, b.po_no, b.skids,
b.ship_to_region, b.tare_wt, b.freight_type, b.who_entered, b.date_entered, b.void, b.void_who,
b.void_date, b.ship_to_note, b.notes,

bl.bl_no, bl.order_no, bl.order_ext, bl.line_no, bl.location, bl.freight_class, bl.description,
bl.time_entered, bl.shipped, bl.note, bl.note_flag, bl.who_entered, bl.uom, bl.misc, bl.weight, bl.dot,
bl.hm, bl.uom2, bl.shipped2, bl.bl_type, bl.part_no, bl.po_no, bl.conv_factor, bl.conv_factor2,

l.name,   
l.addr1,   
l.addr2,   
l.addr3,   
l.addr4,   
l.addr5,''' + @home_curr + '''
FROM bol b
left outer join locations_all l (nolock) on ( b.location = l.location) 
join bol_list bl (nolock) on ( b.bl_no = bl.bl_no ) 
WHERE b.bl_no = ''' + @bol + '''' )


update #rpt_bol
set b_currency_code = r.currency_key
from rtv_all r
where b_bl_type = 'R' and b_bl_src_no = r.rtv_no

update #rpt_bol
set b_currency_code = o.curr_key
from orders_all o
where b_bl_type = 'C' and b_bl_src_no = o.order_no and b_bl_src_ext = o.ext

select r.* ,
isnull(sv.ship_via_name,r.b_routing),
isnull(ft.description,r.b_freight_type),
g.currency_mask,   g.curr_precision, g.rounding_factor, 
case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2 
  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
g.symbol,
case when g.neg_num_format < 9 then '' when g.neg_num_format in (9,11,14,16) then 'b' else 'a' end,
'.',',',
isnull((select count(*) from notes n (nolock) where n.code = convert(varchar(10),r.b_bl_src_no) and n.code_type = 'O' and
  n.bol = 'Y' and r.b_bl_type = 'C'),0)

from #rpt_bol r
left outer join arshipv sv on sv.ship_via_code = r.b_routing
left outer join freight_type ft on ft.kys = r.b_freight_type
left outer join glcurr_vw g on g.currency_code = r.b_currency_code
order by r.b_bl_no,l_line_no
end 
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_bol] TO [public]
GO
