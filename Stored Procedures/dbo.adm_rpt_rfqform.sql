SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_rfqform] @process_ctrl_num varchar(32) as


BEGIN
set nocount on

declare @po_no varchar(16), @range varchar(2000), @vend varchar(255),
  @pos int, @parent_id int

select @po_no = registry_data, @parent_id = registry_id
from registry
where registry_name = @process_ctrl_num and registry_type = 'P'
and parent_id is null

select @vend = isnull((select min(registry_data) from registry 
  where parent_id = @parent_id and registry_type = 'V'),NULL)

select @range = ''
while @vend is not null
begin
  if @range = ''
    select @range = '('
  else
    select @range = @range + ' or '

  select @pos = charindex(':',@vend)
  select @range = @range + ' a.vendor_code = ''' + substring(@vend,(@pos+1),255) + ''''

  select @vend = isnull((select min(registry_data) from registry 
    where parent_id = @parent_id and registry_type = 'V' and registry_data > @vend),NULL)
end
if @range != ''
  select @range = @range + ')'
else
  select @range = '( 0 = 0 )'

delete from registry 
where registry_id = @parent_id

exec ('SELECT p.po_no, 
p.status, 
p.po_type, 
p.printed, 
a.vendor_code, 
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
isnull(a.attention_name,''''), 
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
l.unit_cost, l.unit_measure, l.note, l.rel_date, l.qty_ordered, l.qty_received, l.who_entered,
l.status, l.ext_cost, l.conv_factor, l.void, l.void_who, l.void_date, l.lb_tracking, l.line,
l.taxable, l.prev_qty, l.po_key, l.weight_ea, l.row_id, l.tax_code, l.curr_factor,
l.oper_factor, l.total_tax, l.curr_cost, l.oper_cost, l.reference_code, l.project1, l.project2,
l.project3, l.tolerance_code, l.shipto_code, l.receiving_loc, l.shipto_name, l.addr1, l.addr2,
l.addr3, l.addr4, l.addr5, l.receipt_batch_no,
datalength(rtrim(replace(cast((l.qty_ordered) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((l.qty_ordered) as varchar(40))),
datalength(rtrim(replace(cast((l.qty_received) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((l.qty_received) as varchar(40))),
datalength(rtrim(replace(cast(l.curr_cost as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast(l.curr_cost as varchar(40))),

r.location, r.part_type, r.release_date, r.quantity, r.received,
r.status, r.confirm_date, r.confirmed, r.lb_tracking, r.conv_factor, r.prev_qty, r.po_key,
r.row_id, r.due_date, r.ord_line, r.po_line, r.receipt_batch_no,
case when p.printed > ''N'' and r.prev_qty != r.quantity then 1 else 0 end, -- change
datalength(rtrim(replace(cast((r.quantity) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((r.quantity) as varchar(40))),
datalength(rtrim(replace(cast((r.received) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((r.received) as varchar(40))),

a.vendor_name,   a.addr1, a.addr2,   a.addr3,   a.addr4,   a.addr5,   a.addr6,   
isnull(c.company_name,''''),   
isnull(c.addr1,''''),   
isnull(c.addr2,''''),   
isnull(c.addr3,''''),   
isnull(c.addr4,''''),   
isnull(c.addr5,''''),   
isnull(c.addr6,''''),   
g.currency_mask,   g.curr_precision, g.rounding_factor, 
case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2 
  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
g.symbol,
case when g.neg_num_format < 9 then '''' when g.neg_num_format in (9,11,14,16) then ''b'' else ''a'' end,
''.'','','',
h.currency_mask,   h.curr_precision, h.rounding_factor, 
case when h.neg_num_format in (0,1,2,10,15) then 1 when h.neg_num_format in (6,7,9,14) then 2 
  when h.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when h.neg_num_format in (2,3,6,9,10,13) then 1 when h.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
h.symbol,
case when h.neg_num_format < 9 then '''' when h.neg_num_format in (9,11,14,16) then ''b'' else ''a'' end,
''.'','','',
isnull((select ship_via_name from arshipv (nolock) where ship_via_code = p.ship_via),p.ship_via),
isnull((select fob_desc from apfob (nolock) where fob_code = p.fob),p.fob),
isnull((select terms_desc from apterms (nolock) where terms_code = p.terms),p.terms),
isnull((select tax_desc from aptax (nolock) where tax_code = p.tax_code),p.tax_code),
isnull((select tax_desc from aptax (nolock) where tax_code = l.tax_code),l.tax_code),
isnull((select description from buyers (nolock) where kys = p.buyer),p.buyer),
isnull((select category_desc from po_usrcateg (nolock) where category_code = p.user_category),p.user_category),
isnull((select user_stat_desc from po_usrstat (nolock) where user_stat_code = p.user_code and status_code = p.status),p.user_code),
isnull((select description from tolerance (nolock) where tolerance_cd = l.tolerance_code),l.tolerance_code),
l.shipto_name + replicate('' '',40-datalength(l.shipto_name)) +
l.addr1 + replicate('' '',40-datalength(l.addr1)) +
l.addr2 + replicate('' '',40-datalength(l.addr2)) +
l.addr3 + replicate('' '',40-datalength(l.addr3)) +
l.addr4 + replicate('' '',40-datalength(l.addr4)) +
l.addr5 + replicate('' '',40-datalength(l.addr5)) ,
a.vendor_code,
isnull((select min(note_no) from notes n where n.code = p.po_no and n.code_type = ''P'' and n.form = ''Y''),-1),
case when isnull(a.check_extendedname_flag,0) = 1 then a.extended_name else a.vendor_name end -- extended_name
from purchase_all p 
join pur_list l on l.po_no = p.po_no
join releases r on r.po_no = p.po_no and r.po_line = l.line and r.part_no = l.part_no
join glco gl on 1 = 1
left outer join adm_vend_all a on 1=1
left outer join glcurr_vw g on g.currency_code = p.curr_key
left outer join glcurr_vw h on h.currency_code = gl.home_currency
join apco c on 1 = 1
where isnull(p.approval_flag,0) = 0 and p.po_no = ''' + @po_no + ''' and ' + @range + '
and isnull(p.tax_valid_ind,1) = 1
order by a.vendor_code, l.line, l.rel_date' )
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_rfqform] TO [public]
GO
