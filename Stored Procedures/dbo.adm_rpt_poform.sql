
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[adm_rpt_poform] @order int = 0, @po_no varchar(16) = '', 
@range varchar(8000) = '0=0' as
begin
set nocount on

--v2.0	TM	04/18/2012 - Place Product Type into Project_3
--v2.1  CB	24/11/2015 - Outsourcing - replace make process with final frame part number and description
create table #po (po_key int, po_ext int NULL, printed char(1))

select @range = replace(@range,'"','''')
if @po_no != ''
begin
exec('insert #po
  select po_key, po_ext, printed  from purchase_all p (nolock), adm_vend v (nolock)
  where p.vendor_no = v.vendor_code and p.status != ''H'' and p.status != ''V'' 
  and isnull(p.approval_flag,0) = 0
  and isnull(p.tax_valid_ind,1) = 1 and isnull(etransmit_status,''T'') = ''T'' and po_no = ''' + @po_no + '''') 
end
else
begin
if charindex('po_key',@range) > 0
begin
exec('insert #po
  select distinct po_key, po_ext, printed  from purchase (nolock), adm_vend v (nolock), locations l (nolock), region_vw r (nolock)
  where purchase.vendor_no = v.vendor_code and purchase.status != ''H'' 
   and isnull(purchase.approval_flag,0) = 0 and
   l.location = purchase.location and 
   l.organization_id = r.org_id 
  and isnull(purchase.tax_valid_ind,1) = 1 and purchase.status != ''V'' and isnull(purchase.etransmit_status,''T'') = ''T'' and ' + @range) 
end
else
begin
exec('insert #po
  select distinct po_key, po_ext, printed  from purchase (nolock), adm_vend v (nolock), locations l (nolock), region_vw r (nolock)
  where purchase.vendor_no = v.vendor_code and purchase.status > ''H'' 
   and isnull(purchase.approval_flag,0) = 0 and
   l.location = purchase.location and 
   l.organization_id = r.org_id 
  and isnull(purchase.tax_valid_ind,1) = 1 and purchase.status != ''V'' and purchase.printed >= ''N'' and printed < ''Y'' and purchase.etransmit_status is NULL
  and ' + @range)
end
end

update p
set printed = 'Y',
  po_ext = case when p.printed > 'N' then isnull(p.po_ext,0) + 1 else isnull(p.po_ext,0) end
from purchase_all p, #po t
where p.po_key = t.po_key

create table #rpt_poform (
p_po_no varchar(16) NULL,  p_status char(1) NULL,  p_po_type char(2) NULL,  p_printed char(1) NULL, 
p_vendor_no varchar(12) NULL,  p_date_of_order datetime NULL,  p_date_order_due datetime NULL, 
p_ship_to_no varchar(10) NULL,  p_ship_name varchar(40) NULL,  p_ship_address1 varchar(40) NULL, 
p_ship_address2 varchar(40) NULL,  p_ship_address3 varchar(40) NULL,  p_ship_address4 varchar(40) NULL, 
p_ship_address5 varchar(40) NULL,  p_ship_city varchar(40) NULL,  p_ship_state varchar(40) NULL, 
p_ship_zip varchar(10) NULL,  p_ship_via varchar(10) NULL,  p_fob varchar(10) NULL,  p_tax_code varchar(10) NULL, 
p_terms varchar(10) NULL,  p_attn varchar(30) NULL,  p_footing varchar(255) NULL,  p_blanket char(1) NULL, 
p_who_entered varchar(20) NULL,  p_total_amt_order decimal(20,8) NULL,  p_freight decimal(20,8) NULL, 
p_date_to_pay datetime NULL,  p_discount decimal(20,8) NULL,  p_prepaid_amt decimal(20,8) NULL, 
p_vend_inv_no varchar(20) NULL,  p_email char(1) NULL,  p_email_name varchar(20) NULL,  p_freight_flag char(1) NULL, 
p_freight_vendor varchar(12) NULL,  p_freight_inv_no varchar(20) NULL,  p_void char(1) NULL, 
p_void_who varchar(20) NULL,  p_void_date datetime NULL,  p_note varchar(255) NULL,  p_po_key int NULL, 
p_po_ext int NULL,  p_curr_key varchar(10) NULL,  p_curr_type char(1) NULL,  p_curr_factor decimal(20,8) NULL, 
p_buyer varchar(10) NULL,  p_location varchar(10) NULL,  p_prod_no int NULL,  p_oper_factor decimal(20,8) NULL, 
p_hold_reason varchar(10) NULL,  p_phone varchar(30) NULL,  p_total_tax decimal(20,8) NULL, 
p_rate_type_home varchar(8) NULL,  p_rate_type_oper varchar(8) NULL,  p_reference_code varchar(32) NULL, 
p_posting_code varchar(8) NULL,  p_user_code varchar(8) NULL,  p_expedite_flag smallint NULL, 
p_vend_order_no varchar(16) NULL,  p_requested_by varchar(40) NULL,  p_approved_by varchar(40) NULL, 
p_user_category varchar(8) NULL,  p_blanket_flag smallint NULL,  p_date_blnk_from datetime NULL, 
p_date_blnk_to datetime NULL,  p_amt_blnk_limit float NULL,
l_part_no varchar(30) NULL,  l_location varchar(10) NULL,  l_type char(1) NULL, 
l_vend_sku varchar(30) NULL,  l_account_no varchar(32) NULL,  l_description varchar(255) NULL, 
l_unit_cost decimal(20,8) NULL,  l_unit_measure varchar(2) NULL,  l_note varchar(255) NULL, 
l_rel_date datetime NULL,  l_qty_ordered decimal(20,8) NULL,  l_qty_received decimal(20,8) NULL, 
l_who_entered varchar(20) NULL,  l_status char(1) NULL,  l_ext_cost decimal(20,8) NULL, 
l_conv_factor decimal(20,8) NULL,  l_void char(1) NULL,  l_void_who varchar(20) NULL,  l_void_date datetime NULL, 
l_lb_tracking char(1) NULL,  l_line int NULL,  l_taxable int NULL,  l_prev_qty decimal(20,8) NULL,  l_po_key int NULL, 
l_weight_ea decimal(20,8) NULL,  l_row_id int NULL,  l_tax_code varchar(10) NULL,  l_curr_factor decimal(20,8) NULL, 
l_oper_factor decimal(20,8) NULL,  l_total_tax decimal(20,8) NULL,  l_curr_cost decimal(20,8) NULL, 
l_oper_cost decimal(20,8) NULL,  l_reference_code varchar(32) NULL,  l_project1 varchar(75) NULL, 
l_project2 varchar(75) NULL,  l_project3 varchar(75) NULL,  l_tolerance_code varchar(10) NULL, 
l_shipto_code varchar(10) NULL,  l_receiving_loc varchar(10) NULL,  l_shipto_name varchar(40) NULL, 
l_addr1 varchar(40) NULL,  l_addr2 varchar(40) NULL,  l_addr3 varchar(40) NULL,  l_addr4 varchar(40) NULL, 
l_addr5 varchar(40) NULL,  l_receipt_batch_no int NULL,
l_ord_precision int NULL,
l_rcv_precision int NULL,
l_cost_precision int NULL,

r_location varchar(10) NULL, 
r_part_type varchar(10) NULL,  r_release_date datetime NULL,  r_quantity decimal(20,8) NULL, 
r_received decimal(20,8) NULL,  r_status char(1) NULL,  r_confirm_date datetime NULL,  r_confirmed char(1) NULL, 
r_lb_tracking char(1) NULL,  r_conv_factor decimal(20,8) NULL,  r_prev_qty decimal(20,8) NULL,  r_po_key int NULL, 
r_row_id int NULL,  r_due_date datetime NULL,  r_ord_line int NULL,  r_po_line int NULL,  r_receipt_batch_no int NULL,
r_change int NULL,
r_ord_precision int NULL,
r_rcv_precision int NULL,

a_vendor_name varchar(40) NULL , a_addr1 varchar(40) NULL , a_addr2 varchar(40) NULL ,
a_addr3 varchar(40) NULL , a_addr4 varchar(40) NULL , a_addr5 varchar(40) NULL , a_addr6 varchar(40) NULL ,
co_company_name varchar(30) NULL,  co_addr1 varchar(40) NULL,  co_addr2 varchar(40) NULL,  co_addr3 varchar(40) NULL,  
co_addr4 varchar(40) NULL, co_addr5 varchar(40) NULL,  co_addr6 varchar(40) NULL, 
g_currency_mask varchar(100) NULL, g_curr_precision smallint NULL, 
g_rounding_factor int NULL, g_position int NULL, g_neg_num_format int NULL, g_symbol varchar(8) null, g_symbol_space char(1) NULL,
g_dec_separator char(1) null, g_thou_separator char(1) null,
h_currency_mask varchar(100) NULL, h_curr_precision smallint NULL,
h_rounding_factor int NULL, h_position int NULL, h_neg_num_format int NULL, h_symbol char(8) null, h_symbol_space char(1) NULL,
h_dec_separator char(1) null, h_thou_separator char(1) null,
p_ship_via_name varchar(50) NULL, p_fob_desc varchar(50) NULL, p_terms_desc varchar(50) NULL,
p_tax_desc varchar(50) NULL, l_tax_desc varchar(50) NULL,
p_buyer_name varchar(50) NULL, p_category_code varchar(50) NULL,
p_user_status_descr varchar(50) NULL, l_tolerance_descr varchar(50) NULL,
p_ship_group varchar(240) null,
p_sort_order varchar(20) NULL,
n_note_no int NULL,
o_cust_code varchar(10) NULL, o_attention varchar(40) NULL, o_phone varchar(20) NULL,
o_masked_phone varchar(100) NULL,
a_extended_name varchar(120) NULL
)

create index p1 on #rpt_poform (p_vendor_no,p_po_key,l_shipto_code, l_shipto_name, l_addr1, l_addr2,l_addr3,l_addr4,l_addr5)
create index p2 on #rpt_poform (p_po_key,l_shipto_code, l_shipto_name, l_addr1, l_addr2,l_addr3,l_addr4,l_addr5)
create index p3 on #rpt_poform (p_po_key,o_phone)

insert #rpt_poform
SELECT p.po_no, 
p.status, 
p.po_type, 
t.printed, 
p.vendor_no, 
p.date_of_order, 
p.date_order_due,
p.ship_to_no, 
p.ship_name, 
p.ship_address1, 
p.ship_address2, 
p.ship_address3, 
p.ship_address4,
p.ship_address5, 
p.ship_city, 
p.ship_state, 
p.ship_zip, 
p.ship_via, 
p.fob, 
p.tax_code, 
p.terms,
isnull(p.attn,''), 
p.footing, 
p.blanket, 
p.who_entered, 
p.total_amt_order, 
p.freight, 
p.date_to_pay,
p.discount, 
p.prepaid_amt, 
p.vend_inv_no, 
p.email, 
p.email_name, 
p.freight_flag,
p.freight_vendor, 
p.freight_inv_no, p.void, p.void_who, p.void_date, p.note, p.po_key,
p.po_ext, p.curr_key, p.curr_type, p.curr_factor, p.buyer, p.location, p.prod_no,
p.oper_factor, p.hold_reason, p.phone, p.total_tax, p.rate_type_home, p.rate_type_oper,
p.reference_code, p.posting_code, p.user_code, p.expedite_flag, p.vend_order_no,
p.requested_by, p.approved_by, p.user_category, p.blanket_flag, p.date_blnk_from,
p.date_blnk_to, p.amt_blnk_limit,
l.part_no, l.location, l.type, l.vend_sku, l.account_no, l.description,
-- l.unit_cost, l.unit_measure, l.note, l.rel_date, l.qty_ordered, l.qty_received, l.who_entered,
l.unit_cost, l.unit_measure, l.note, r.due_date, l.qty_ordered, l.qty_received, l.who_entered,
l.status, l.ext_cost, l.conv_factor, l.void, l.void_who, l.void_date, l.lb_tracking, l.line,
l.taxable, l.prev_qty, l.po_key, l.weight_ea, l.row_id, l.tax_code, l.curr_factor,
l.oper_factor, l.total_tax, l.curr_cost, l.oper_cost, l.reference_code, l.project1, l.project2,
l.project3, l.tolerance_code, l.shipto_code, l.receiving_loc, l.shipto_name, l.addr1, l.addr2,
l.addr3, l.addr4, l.addr5, l.receipt_batch_no,
datalength(rtrim(replace(cast((l.qty_ordered) as varchar(40)),'0',' '))) - 
charindex('.',cast((l.qty_ordered) as varchar(40))),
datalength(rtrim(replace(cast((l.qty_received) as varchar(40)),'0',' '))) - 
charindex('.',cast((l.qty_received) as varchar(40))),
datalength(rtrim(replace(cast(l.curr_cost as varchar(40)),'0',' '))) - 
charindex('.',cast(l.curr_cost as varchar(40))),


r.location, r.part_type, r.release_date, r.quantity, r.received,
r.status, r.confirm_date, r.confirmed, r.lb_tracking, r.conv_factor, r.prev_qty, r.po_key,
r.row_id, r.due_date, r.ord_line, r.po_line, r.receipt_batch_no,
case when p.printed > 'N' and r.prev_qty != r.quantity then 1 else 0 end, -- change
datalength(rtrim(replace(cast((r.quantity) as varchar(40)),'0',' '))) - 
charindex('.',cast((r.quantity) as varchar(40))),
datalength(rtrim(replace(cast((r.received) as varchar(40)),'0',' '))) - 
charindex('.',cast((r.received) as varchar(40))),

case isnull(p.one_time_vend_ind,0) when 1 then p.vendor_addr1 else a.vendor_name end,
case isnull(p.one_time_vend_ind,0) when 1 then p.vendor_addr1 else a.addr1 end,
case isnull(p.one_time_vend_ind,0) when 1 then p.vendor_addr2 else a.addr2 end,
case isnull(p.one_time_vend_ind,0) when 1 then p.vendor_addr3 else a.addr3 end,
case isnull(p.one_time_vend_ind,0) when 1 then p.vendor_addr4 else a.addr4 end,
case isnull(p.one_time_vend_ind,0) when 1 then p.vendor_addr5 else a.addr5 end,
case isnull(p.one_time_vend_ind,0) when 1 then p.vendor_addr6 else a.addr6 end,
--a.vendor_name,   
--a.addr1, a.addr2,   a.addr3,   a.addr4,   a.addr5,   a.addr6,   
isnull(c.company_name,''),   
isnull(c.addr1,''),   
isnull(c.addr2,''),   
isnull(c.addr3,''),   
isnull(c.addr4,''),   
isnull(c.addr5,''),   
isnull(c.addr6,''),   
g.currency_mask,   g.curr_precision, g.rounding_factor, 
case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2 
  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
g.symbol,
case when g.neg_num_format < 9 then '' when g.neg_num_format in (9,11,14,16) then 'b' else 'a' end,
'.',',',
h.currency_mask,   h.curr_precision, h.rounding_factor, 
case when h.neg_num_format in (0,1,2,10,15) then 1 when h.neg_num_format in (6,7,9,14) then 2 
  when h.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when h.neg_num_format in (2,3,6,9,10,13) then 1 when h.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
h.symbol,
case when h.neg_num_format < 9 then '' when h.neg_num_format in (9,11,14,16) then 'b' else 'a' end,
'.',',',
isnull((select ship_via_name from arshipv (nolock) where ship_via_code = p.ship_via),p.ship_via),
isnull((select fob_desc from apfob (nolock) where fob_code = p.fob),p.fob),
isnull((select terms_desc from apterms (nolock) where terms_code = p.terms),p.terms),
isnull((select tax_desc from aptax (nolock) where tax_code = p.tax_code),p.tax_code),
isnull((select tax_desc from aptax (nolock) where tax_code = l.tax_code),l.tax_code),
isnull((select description from buyers (nolock) where kys = p.buyer),p.buyer),
isnull((select category_desc from po_usrcateg (nolock) where category_code = p.user_category),p.user_category),
isnull((select user_stat_desc from po_usrstat (nolock) where user_stat_code = p.user_code and status_code = p.status),p.user_code),
isnull((select description from tolerance (nolock) where tolerance_cd = l.tolerance_code),l.tolerance_code),
l.shipto_name + replicate(' ',40-datalength(l.shipto_name)) +
l.addr1 + replicate(' ',40-datalength(l.addr1)) +
l.addr2 + replicate(' ',40-datalength(l.addr2)) +
l.addr3 + replicate(' ',40-datalength(l.addr3)) +
l.addr4 + replicate(' ',40-datalength(l.addr4)) +
l.addr5 + replicate(' ',40-datalength(l.addr5)) ,
case when @order = 0 then p.vendor_no else p.po_no end,
isnull((select min(note_no) from notes n where n.code = p.po_no and n.code_type = 'P' and n.form = 'Y'),-1),
o.cust_code,
o.attention,
o.phone,
o.phone,
case isnull(p.one_time_vend_ind,0) when 1  then p.vendor_addr1 else 
case when isnull(a.check_extendedname_flag,0) = 1 then a.extended_name else a.vendor_name end end -- extended_name
from #po t
join purchase_all p on p.po_key = t.po_key
join pur_list l on l.po_no = p.po_no
join releases r on r.po_no = p.po_no and r.po_line = l.line and r.part_no = l.part_no
join glco gl on 1 = 1
left outer join adm_vend_all a on a.vendor_code = p.vendor_no
left outer join glcurr_vw g on g.currency_code = p.curr_key
left outer join glcurr_vw h on h.currency_code = gl.home_currency
left outer join (select o.order_no, max(o.ext), oap1.line_no, oap1.po_no from orders_auto_po oap1, orders_all o
  where oap1.order_no = o.order_no group by o.order_no, oap1.line_no, oap1.po_no) as oap(order_no,ext,line_no, po_no)
  on oap.po_no = p.po_no and oap.line_no = r.ord_line
left outer join orders_all o on o.order_no = oap.order_no and o.ext = oap.ext
join apco c on 1 = 1
order by 
case when @order = 0 then p.vendor_no else '' end,p.po_key,l.shipto_code, l.shipto_name, l.addr1, l.addr2,l.addr3,l.addr4,l.addr5



declare @mask varchar(100), @phone varchar(50), @orig_mask varchar(100)
declare @po int, @pos int
select @orig_mask = isnull((select mask from masktbl (nolock)
  where lower(mask_name) = 'phone number mask'),'(###) ###-#### Ext. ####')

DECLARE pickcursor CURSOR LOCAL FOR
SELECT distinct p_po_key, o_phone
from #rpt_poform
where isnull(o_phone,'') != ''
OPEN pickcursor
FETCH NEXT FROM pickcursor INTO @po, @phone

While @@FETCH_STATUS = 0
begin
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

  update #rpt_poform
  set o_masked_phone = @mask
  where p_po_key = @po
FETCH NEXT FROM pickcursor INTO @po, @phone
end

close pickcursor
deallocate pickcursor

--
-- Set the Project field to the UPC Code for Printing
--
update #rpt_poform														-- V1.0  /  McGrady
set l_project1 = SUBSTRING(u.upc,1,1)+'-'+SUBSTRING(u.upc,2,5)+'-'+		-- V1.0  /  McGrady
				 SUBSTRING(u.upc,7,5)+'-'+SUBSTRING(u.upc,12,1)			-- V1.0  /  McGrady
from #rpt_poform r, uom_id_code u (nolock)								-- V1.0  /  McGrady
where r.l_part_no = u.part_no											-- V1.0  /  McGrady
--

--v2.0 Reset Line sequencing based on Product Type
update #rpt_poform														--v2.0
set l_project3 = CASE i.type_code WHEN 'FRAME'	THEN 'S1'				--v2.0
								  WHEN 'SUN'	THEN 'S1'				--v2.0
								  ELSE 'S9' END							--v2.0
from #rpt_poform r, inv_master i (nolock)								--v2.0
where r.l_part_no = i.part_no											--v2.0
--v2.0

-- v2.1 Start
UPDATE	a
SET		l_part_no = c.asm_no,
		l_description = d.description
FROM	#rpt_poform a
JOIN	inv_master b (NOLOCK)
ON		a.l_part_no = b.part_no 
JOIN	what_part c (NOLOCK)
ON		a.l_part_no = c.part_no
JOIN	inv_master d (NOLOCK)
ON		c.asm_no = d.part_no
WHERE	b.status = 'Q'
-- v2.1 End


select * from #rpt_poform
order by 
case when @order = 0 then p_vendor_no else '' end,
p_po_key,l_shipto_code, l_shipto_name, l_addr1, l_addr2,l_addr3,l_addr4,l_addr5,l_project3,l_part_no		--v2.0

end
GO

GRANT EXECUTE ON  [dbo].[adm_rpt_poform] TO [public]
GO
