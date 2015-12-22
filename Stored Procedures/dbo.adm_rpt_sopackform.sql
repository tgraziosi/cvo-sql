SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_sopackform] @process_ctrl_num varchar(16)
as
begin
declare @order int, @ext int, @load_no int, @temp varchar(16), @len int

create table #orders (order_no int, ext int, phone varchar(50) null, masked_phone varchar(100) NULL)
set nocount on

if @process_ctrl_num like 'L:%'
begin
  select @load_no = substring(@process_ctrl_num,3,16)

  insert #orders
  select l.order_no, l.order_ext, o.phone, ''
  from load_list l, orders_all o 
  where l.order_no = o.order_no and l.order_ext = o.ext and l.load_no = @load_no 
    and o.type = 'I' and o.status < 'V'
end
else
begin
  select @len = charindex('-',@process_ctrl_num,1)-1
  select @temp = left(@process_ctrl_num,@len)
  select @order = convert(int,@temp)
  select @len = @len + 2
  select @temp = convert(int,substring(@process_ctrl_num,@len,16))
  select @ext = convert(int,@temp)

  insert #orders
  select o.order_no, o.ext, o.phone, ''
  from orders_all o
  where o.order_no = @order and o.ext = @ext and o.type = 'I' and o.status < 'V'
end

declare @mask varchar(100), @phone varchar(50), @orig_mask varchar(100)
declare @pos int, @orig_phone varchar(50)

select @orig_mask = isnull((select mask from masktbl
where lower(mask_name) = 'phone number mask'),'(###) ###-#### Ext. ####')

select @orig_phone = isnull((select min(phone) from #orders where phone is not null),NULL)

while @orig_phone is not null
begin
  select @pos = 0, @mask = ''
  if @orig_phone != ''
  begin
    select @phone = @orig_phone
    select @mask = @orig_mask
    select @mask = replace(@mask,'!','#')
    select @mask = replace(@mask,'@','#')
    select @mask = replace(@mask,'?','#')

    while @phone != ''
    begin
      select @pos = charindex('#',@mask)

      if @pos > 0
        select @mask = stuff(@mask,@pos,1,substring(@phone,1,1))
      else
        select @mask = @mask + substring(@phone,1,1)

      select @phone = ltrim(substring(@phone,2,100))
    end

    if @pos > 0
      select @mask = substring(@mask,1,@pos)
  end

  if @mask != ''
    update #orders
    set masked_phone = @mask
    where phone = @orig_phone

  select @orig_phone = isnull((select min(phone) from #orders where isnull(phone,'') > @orig_phone),NULL)
end -- while

SELECT 
convert(varchar(11),o.order_no),
convert(varchar(10),o.ext),
o.cust_code,
o.ship_to,
o.req_ship_date,
o.sch_ship_date,
o.date_shipped,
o.date_entered,
o.cust_po,
o.who_entered,
o.status,
o.attention,
o.phone,
o.terms,
o.routing,
o.special_instr,
o.invoice_date,
o.total_invoice,
o.total_amt_order,
o.salesperson,
o.tax_id,
o.tax_perc,
o.invoice_no,
o.fob,
o.freight,
o.printed,
o.discount,
o.label_no,
o.cancel_date,
o.new,
o.ship_to_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_add_3,
o.ship_to_add_4,
o.ship_to_add_5,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
o.ship_to_country,
o.ship_to_region,
o.cash_flag,
o.type,
o.back_ord_flag,
o.freight_allow_pct,
o.route_code,
o.route_no,
o.date_printed,
o.date_transfered,
o.cr_invoice_no,
o.who_picked,
o.note,
o.void,
o.void_who,
o.void_date,
o.changed,
isnull(o.remit_key,''),
o.forwarder_key,
o.freight_to,
o.sales_comm,
o.freight_allow_type,
o.cust_dfpa,
o.location,
o.total_tax,
o.total_discount,
o.f_note,
o.invoice_edi,
o.edi_batch,
o.post_edi_date,
o.blanket,
o.gross_sales,
o.load_no,
o.curr_key,
o.curr_type,
o.curr_factor,
o.bill_to_key,
o.oper_factor,
o.tot_ord_tax,
o.tot_ord_disc,
o.tot_ord_freight,
o.posting_code,
o.rate_type_home,
o.rate_type_oper,
o.reference_code,
o.hold_reason,
o.dest_zone_code,
o.orig_no,
o.orig_ext,
o.tot_tax_incl,
o.process_ctrl_num,
o.batch_code,
o.tot_ord_incl,
o.barcode_status,
o.multiple_flag,
o.so_priority_code,
o.FO_order_no,

l.line_no,
l.location,
l.part_no,
isnull(l.description,''),
l.time_entered,
l.ordered,
l.shipped,
l.price,
l.price_type,
isnull(l.note,''),
l.status,
l.cost,
l.who_entered,
l.sales_comm,
l.temp_price,
l.temp_type,
l.cr_ordered,
l.cr_shipped,
l.discount,
l.uom,
l.conv_factor,
l.void,
l.void_who,
l.void_date,
l.std_cost,
l.cubic_feet,
l.printed,
l.lb_tracking,
l.labor,
l.direct_dolrs,
l.ovhd_dolrs,
l.util_dolrs,
l.taxable,
l.weight_ea,
l.qc_flag,
l.reason_code,
l.row_id,
l.qc_no,
l.rejected,
l.part_type,
isnull(l.orig_part_no,''),
l.back_ord_flag,
l.gl_rev_acct,
l.total_tax,
l.tax_code,
l.curr_price,
l.oper_price,
l.display_line,
l.std_direct_dolrs,
l.std_ovhd_dolrs,
l.std_util_dolrs,
l.reference_code,
l.contract,
l.agreement_id,
l.ship_to,
l.service_agreement_flag,
l.inv_available_flag,
datalength(rtrim(replace(cast((l.ordered + l.cr_ordered) as varchar(40)),'0',' '))) - 
charindex('.',cast((l.ordered + l.cr_ordered) as varchar(40))),	-- ordered qty precision
datalength(rtrim(replace(cast((l.shipped + l.cr_shipped) as varchar(40)),'0',' '))) - 
charindex('.',cast((l.shipped + l.cr_shipped) as varchar(40))),	-- shipped qty precision
datalength(rtrim(replace(cast(l.curr_price as varchar(40)),'0',' '))) - 
charindex('.',cast(l.curr_price as varchar(40))),		-- price precision
c.customer_name,   
isnull(c.addr1,''),
isnull(c.addr2,''),   
isnull(c.addr3,''),   
isnull(c.addr4,''),   
isnull(c.addr5,''),   
isnull(c.addr6,''),
c.contact_name,   
c.inv_comment_code,   
c.city,
c.state,   
c.postal_code,
c.country,

loc.name,
loc.addr1,
loc.addr2,
loc.addr3,
loc.addr4,
loc.addr5,

isnull(v.ship_via_name,o.routing),
replicate (' ',11 - datalength(convert(varchar(11),o.order_no))) + convert(varchar(11),o.order_no) + '.' +
replicate (' ',5 - datalength(convert(varchar(5),o.ext))) + convert(varchar(5),o.ext),

tt.masked_phone,  -- o_masked_phone

isnull(lbs.lot_ser,''),
lbs.bin_no,
lbs.qty,
lbs.uom_qty,
lbs.date_expires,
datalength(rtrim(replace(cast((l.ordered + l.cr_ordered) as varchar(40)),'0',' '))) - 
charindex('.',cast((l.ordered + l.cr_ordered) as varchar(40))), -- lot qty precision

'.',
',',
case when isnull(c.check_extendedname_flag,0) = 1 then c.extended_name else c.customer_name end -- extended_name
from dbo.orders_all o 
join #orders tt on tt.order_no = o.order_no and tt.ext = o.ext
join dbo.ord_list l on l.order_no = o.order_no and l.order_ext = o.ext
join dbo.adm_cust_all c on c.customer_code = o.cust_code   
left outer join dbo.lot_bin_ship lbs on lbs.tran_no = o.order_no and lbs.tran_ext = o.ext and
  lbs.part_no = l.part_no and lbs.location = l.location and lbs.line_no = l.line_no
left outer join dbo.locations_all loc on loc.location = l.location
left outer join dbo.inv_master m on m.part_no = l.part_no and m.status < 'V' and m.status >= 'R'
left outer join dbo.arshipv v on v.ship_via_code = o.routing
left outer join dbo.freight_type f on f.kys = o.freight_allow_type
left outer join dbo.arfob fob on fob.fob_code = o.fob
left outer join dbo.arterms t on t.terms_code = o.terms
left outer join dbo.artax tax on tax.tax_code = o.tax_id
left outer join dbo.artax taxd on taxd.tax_code = l.tax_code
ORDER BY l.location ASC, l.display_line ASC

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_sopackform] TO [public]
GO
