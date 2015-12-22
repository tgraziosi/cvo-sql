SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_soaform] @process_ctrl_num varchar(32) as
begin
set nocount on


declare @ord_len int, @inv_len int, @inv_cnt int
declare @pos int, @ord varchar(10), @ext varchar(10)

select @pos = charindex('-',@process_ctrl_num)
if @pos > 0
begin
  select @ord = left(@process_ctrl_num,(@pos-1))
  select @ext = substring(@process_ctrl_num,(@pos+1),32)
end

create table #rpt_soaform (
o_order_no int NOT NULL default(-1),
o_ext int NOT NULL  default(-1),
o_cust_code varchar (10) NOT NULL  default(''),
o_ship_to varchar (10) NULL ,
o_req_ship_date datetime NOT NULL  default(getdate()),
o_sch_ship_date datetime NULL ,
o_date_shipped datetime NULL ,
o_date_entered datetime NOT NULL  default(getdate()),
o_cust_po varchar (20) NULL ,
o_who_entered varchar (20) NULL ,
o_status char (1) NOT NULL  default(''),
o_attention varchar (40) NULL ,
o_phone varchar (20) NULL ,
o_terms varchar (10) NULL ,
o_routing varchar (20) NULL ,
o_special_instr varchar (255) NULL ,
o_invoice_date datetime NULL ,
o_total_invoice decimal(20, 8) NOT NULL  default(-1),
o_total_amt_order decimal(20, 8) NOT NULL  default(-1),
o_salesperson varchar (10) NULL ,
o_tax_id varchar (10) NOT NULL  default(''),
o_tax_perc decimal(20, 8) NOT NULL  default(-1),
o_invoice_no int NULL ,
o_fob varchar (10) NULL ,
o_freight decimal(20, 8) NULL ,
o_printed char (1) NULL ,
o_discount decimal(20, 8) NULL ,
o_label_no int NULL ,
o_cancel_date datetime NULL ,
o_new char (1) NULL ,
o_ship_to_name varchar (40) NULL ,
o_ship_to_add_1 varchar (40) NULL ,
o_ship_to_add_2 varchar (40) NULL ,
o_ship_to_add_3 varchar (40) NULL ,
o_ship_to_add_4 varchar (40) NULL ,
o_ship_to_add_5 varchar (40) NULL ,
o_ship_to_city varchar (40) NULL ,
o_ship_to_state varchar (40) NULL ,
o_ship_to_zip varchar (10) NULL ,
o_ship_to_country varchar (40) NULL ,
o_ship_to_region varchar (10) NULL ,
o_cash_flag char (1) NULL ,
o_type char (1) NOT NULL  default('X'),
o_back_ord_flag char (1) NULL ,
o_freight_allow_pct decimal(20, 8) NULL ,
o_route_code varchar (10) NULL ,
o_route_no decimal(20, 8) NULL ,
o_date_printed datetime NULL ,
o_date_transfered datetime NULL ,
o_cr_invoice_no int NULL ,
o_who_picked varchar (20) NULL ,
o_note varchar (255) NULL ,
o_void char (1) NULL ,
o_void_who varchar (20) NULL ,
o_void_date datetime NULL ,
o_changed char (1) NULL ,
o_remit_key varchar (10) NULL ,
o_forwarder_key varchar (10) NULL ,
o_freight_to varchar (10) NULL ,
o_sales_comm decimal(20, 8) NULL ,
o_freight_allow_type varchar (10) NULL ,
o_cust_dfpa char (1) NULL ,
o_location varchar (10) NULL ,
o_total_tax decimal(20, 8) NULL ,
o_total_discount decimal(20, 8) NULL ,
o_f_note varchar (200) NULL ,
o_invoice_edi char (1) NULL ,
o_edi_batch varchar (10) NULL ,
o_post_edi_date datetime NULL ,
o_blanket char (1) NULL ,
o_gross_sales decimal(20, 8) NULL ,
o_load_no int NULL ,
o_curr_key varchar (10) NULL ,
o_curr_type char (1) NULL ,
o_curr_factor decimal(20, 8) NULL ,
o_bill_to_key varchar (10) NULL ,
o_oper_factor decimal(20, 8) NULL ,
o_tot_ord_tax decimal(20, 8) NULL ,
o_tot_ord_disc decimal(20, 8) NULL ,
o_tot_ord_freight decimal(20, 8) NULL ,
o_posting_code varchar (10) NULL ,
o_rate_type_home varchar (8) NULL ,
o_rate_type_oper varchar (8) NULL ,
o_reference_code varchar (32) NULL ,
o_hold_reason varchar (10) NULL ,
o_dest_zone_code varchar (8) NULL ,
o_orig_no int NULL ,
o_orig_ext int NULL ,
o_tot_tax_incl decimal(20, 8) NULL ,
o_process_ctrl_num varchar (32) NULL ,
o_batch_code varchar (16) NULL ,
o_tot_ord_incl decimal(20, 8) NULL ,
o_barcode_status char (2) NULL ,
o_multiple_flag char (1) NOT NULL  default(''),
o_so_priority_code char (1) NULL ,
o_FO_order_no varchar (30) NULL ,
o_blanket_amt float NULL ,
o_user_priority varchar (8) NULL ,
o_user_category varchar (10) NULL ,
o_from_date datetime NULL ,
o_to_date datetime NULL ,
o_consolidate_flag smallint NULL ,
o_proc_inv_no varchar (32) NULL ,
o_sold_to_addr1 varchar (40) NULL ,
o_sold_to_addr2 varchar (40) NULL ,
o_sold_to_addr3 varchar (40) NULL ,
o_sold_to_addr4 varchar (40) NULL ,
o_sold_to_addr5 varchar (40) NULL ,
o_sold_to_addr6 varchar (40) NULL ,
o_user_code varchar (8) NOT NULL  default(''),
o_user_def_fld1 varchar (255) NULL ,
o_user_def_fld2 varchar (255) NULL ,
o_user_def_fld3 varchar (255) NULL ,
o_user_def_fld4 varchar (255) NULL ,
o_user_def_fld5 float NULL ,
o_user_def_fld6 float NULL ,
o_user_def_fld7 float NULL ,
o_user_def_fld8 float NULL ,
o_user_def_fld9 int NULL ,
o_user_def_fld10 int NULL ,
o_user_def_fld11 int NULL ,
o_user_def_fld12 int NULL ,
o_eprocurement_ind int NULL ,
o_sold_to varchar (10) NULL,

l_line_no int NOT NULL  default(-1),
l_location varchar (10) NULL ,
l_part_no varchar (30) NOT NULL  default(''),
l_description varchar (255) NULL ,
l_time_entered datetime NOT NULL  default(getdate()),
l_ordered decimal(20, 8) NOT NULL  default(-1),
l_shipped decimal(20, 8) NOT NULL  default(-1),
l_price decimal(20, 8) NOT NULL  default(-1),
l_price_type char (1) NULL ,
l_note varchar (255) NULL ,
l_status char (1) NOT NULL  default(''),
l_cost decimal(20, 8) NOT NULL  default(-1),
l_who_entered varchar (20) NULL ,
l_sales_comm decimal(20, 8) NOT NULL  default(-1),
l_temp_price decimal(20, 8) NULL ,
l_temp_type char (1) NULL ,
l_cr_ordered decimal(20, 8) NOT NULL  default(-1),
l_cr_shipped decimal(20, 8) NOT NULL  default(-1),
l_discount decimal(20, 8) NOT NULL  default(-1),
l_uom char (2) NULL ,
l_conv_factor decimal(20, 8) NOT NULL  default(-1),
l_void char (1) NULL ,
l_void_who varchar (20) NULL ,
l_void_date datetime NULL ,
l_std_cost decimal(20, 8) NOT NULL  default(-1),
l_cubic_feet decimal(20, 8) NOT NULL  default(-1),
l_printed char (1) NULL ,
l_lb_tracking char (1) NULL ,
l_labor decimal(20, 8) NOT NULL  default(-1),
l_direct_dolrs decimal(20, 8) NOT NULL  default(-1),
l_ovhd_dolrs decimal(20, 8) NOT NULL  default(-1),
l_util_dolrs decimal(20, 8) NOT NULL  default(-1),
l_taxable int NULL ,
l_weight_ea decimal(20, 8) NULL ,
l_qc_flag char (1) NULL ,
l_reason_code varchar (10) NULL ,
l_row_id int NOT NULL  default(-1),
l_qc_no int NULL ,
l_rejected decimal(20, 8) NULL ,
l_part_type char (1) NULL ,
l_orig_part_no varchar (30) NULL ,
l_back_ord_flag char (1) NULL ,
l_gl_rev_acct varchar (32) NULL ,
l_total_tax decimal(20, 8) NOT NULL  default(-1),
l_tax_code varchar (10) NULL ,
l_curr_price decimal(20, 8) NOT NULL  default(-1),
l_oper_price decimal(20, 8) NOT NULL  default(-1),
l_display_line int NOT NULL  default(-1),
l_std_direct_dolrs decimal(20, 8) NULL ,
l_std_ovhd_dolrs decimal(20, 8) NULL ,
l_std_util_dolrs decimal(20, 8) NULL ,
l_reference_code varchar (32) NULL ,
l_contract varchar (16) NULL ,
l_agreement_id varchar (32) NULL ,
l_ship_to varchar (10) NULL ,
l_service_agreement_flag char (1) NULL ,
l_inv_available_flag char (1) NOT NULL  default(''),
l_create_po_flag smallint NULL ,
l_load_group_no int NULL ,
l_return_code varchar (10) NULL ,
l_user_count int NULL ,
l_ord_precision int NULL,
l_shp_precision int NULL,
l_price_precision int NULL,

c_customer_name varchar (40) NULL ,
c_addr1 varchar (40) NULL ,
c_addr2 varchar (40) NULL ,
c_addr3 varchar (40) NULL ,
c_addr4 varchar (40) NULL ,
c_addr5 varchar (40) NULL ,
c_addr6 varchar (40) NULL ,
c_contact_name varchar (40) NULL ,
c_inv_comment_code varchar (8) NULL ,
c_city varchar (40) NULL ,
c_state varchar (40) NULL ,
c_postal_code varchar (15) NULL ,
c_country varchar (40) NULL ,

n_company_name varchar (30) NULL ,
n_addr1 varchar (40) NULL ,
n_addr2 varchar (40) NULL ,
n_addr3 varchar (40) NULL ,
n_addr4 varchar (40) NULL ,
n_addr5 varchar (40) NULL ,
n_addr6 varchar (40) NULL ,

r_name varchar (40) NULL ,
r_addr1 varchar (40) NULL ,
r_addr2 varchar (40) NULL ,
r_addr3 varchar (40) NULL ,
r_addr4 varchar (40) NULL ,
r_addr5 varchar (40) NULL ,

g_currency_mask varchar (100) NULL ,
g_curr_precision smallint NULL ,
g_rounding_factor float NULL ,
g_postion int NULL,
g_neg_num_format int NULL,
g_symbol varchar (8) NULL,
g_symbol_space char (1) NULL,
g_dec_separator char (1) NULL,
g_thou_separator char (1) NULL,

p_amt_payment decimal(20, 8) NULL ,
p_amt_disc_taken decimal(20, 8) NULL ,

m_comment_line varchar (40) NULL ,

i_doc_ctrl_num varchar (16) NULL ,
i_discount decimal (20,8) NULL,
i_tax decimal (20,8) NULL,
i_freight decimal (20,8) NULL,
i_payments decimal (20,8) NULL,
i_total_invoice decimal (20,8) NULL,

v_ship_via_name varchar (40) NULL ,
f_description varchar (40) NULL ,
fob_fob_desc varchar (40) NULL ,
t_terms_desc varchar (30) NULL ,
tax_tax_desc varchar (40) NULL ,
taxd_tax_desc varchar (40) NULL ,

o_sort_order varchar (50) NULL,
o_sort_order2 varchar (50) NULL,
o_sort_order3 varchar (50) NULL,

h_currency_mask varchar (100) NULL ,
h_curr_precision smallint NULL ,
h_rounding_factor float NULL ,
h_position int NULL,
h_neg_num_format int NULL,
h_symbol varchar (8) NULL,
h_symbol_space char (1) NULL,
h_dec_separator char (1) NULL,
h_thou_separator char (1) NULL,

a_note_no int NULL ,
o_masked_phone varchar(100) NULL,
c_extended_name varchar(120) NULL
)

exec('insert #rpt_soaform
SELECT 
o.order_no,
o.ext,
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
isnull(o.remit_key,''''),
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
o.blanket_amt,
o.user_priority,
o.user_category,
o.from_date,
o.to_date,
isnull(o.consolidate_flag,0),
o.proc_inv_no,
o.sold_to_addr1,
o.sold_to_addr2,
o.sold_to_addr3,
o.sold_to_addr4,
o.sold_to_addr5,
o.sold_to_addr6,
o.user_code,
o.user_def_fld1,
o.user_def_fld2,
o.user_def_fld3,
o.user_def_fld4,
o.user_def_fld5,
o.user_def_fld6,
o.user_def_fld7,
o.user_def_fld8,
o.user_def_fld9,
o.user_def_fld10,
o.user_def_fld11,
o.user_def_fld12,
case when o.type != ''I'' then 0 else isnull(o.eprocurement_ind,0) end,
o.sold_to,

l.line_no,
l.location,
l.part_no,
isnull(l.description,''''),
l.time_entered,
l.ordered,
l.shipped,
l.price,
l.price_type,
isnull(l.note,''''),
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
isnull(l.orig_part_no,''''),
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
l.create_po_flag,
l.load_group_no,
l.return_code,
l.user_count,
datalength(rtrim(replace(cast((l.ordered + l.cr_ordered) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((l.ordered + l.cr_ordered) as varchar(40))),
datalength(rtrim(replace(cast((l.shipped + l.cr_shipped) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((l.shipped + l.cr_shipped) as varchar(40))),
datalength(rtrim(replace(cast(l.curr_price as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast(l.curr_price as varchar(40))),

c.customer_name,   
isnull(c.addr1,''''),
isnull(c.addr2,''''),   
isnull(c.addr3,''''),   
isnull(c.addr4,''''),   
isnull(c.addr5,''''),   
isnull(c.addr6,''''),
c.contact_name,   
c.inv_comment_code,   
c.city,
c.state,   
c.postal_code,
c.country,

n.company_name,   
n.addr1,   
n.addr2,   
n.addr3,   
n.addr4,   
n.addr5,   
n.addr6,   

isnull(r.name,''''),
isnull(r.addr1,''''),   
isnull(r.addr2,''''),   
isnull(r.addr3,''''),   
isnull(r.addr4,''''),   
isnull(r.addr5,''''),   

g.currency_mask,   
g.curr_precision, 
g.rounding_factor, 
case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2 
  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
g.symbol,
case when g.neg_num_format < 9 then '''' when g.neg_num_format in (9,11,14,16) then ''b'' else ''a'' end,
''.'',
'','',

p.amt_payment,   
p.amt_disc_taken,   

isnull(m.comment_line ,''''),

i.doc_ctrl_num,
o.tot_ord_disc,
o.tot_ord_tax,
o.tot_ord_freight,
0,
o.total_amt_order -  o.tot_ord_disc  +  o.tot_ord_tax  +  o.tot_ord_freight ,

isnull(v.ship_via_name,o.routing),
isnull(f.description,o.freight_allow_type),
isnull(fob.fob_desc,o.fob),
isnull(t.terms_desc,o.terms),
isnull(tax.tax_desc,o.tax_id),
isnull(taxd.tax_desc,l.tax_code),
o.cust_code,
replicate ('' '',11 - datalength(convert(varchar(11),o.order_no))) + convert(varchar(11),o.order_no) + ''.'' +
replicate ('' '',5 - datalength(convert(varchar(5),o.ext))) + convert(varchar(5),o.ext),
l.location,

'''',2,2,0,1,'''',''b'',''.'','','',
isnull((select min(note_no) from notes n where n.code = convert(varchar(10),o.order_no) and n.code_type = ''O'' and n.form = ''Y''),-1),
o.phone,
case when isnull(c.check_extendedname_flag,0) = 1 then c.extended_name else c.customer_name end -- extended_name
from dbo.orders_all o 
join dbo.ord_list l on l.order_no = o.order_no and l.order_ext = o.ext
join dbo.adm_cust_all c on c.customer_code = o.cust_code   
join dbo.arco n on 1 = 1
left outer join dbo.arremit r on r.kys = o.remit_key
join dbo.glcurr_vw g on g.currency_code = o.curr_key   
left outer join dbo.ord_payment p on p.order_no = o.order_no and p.order_ext = o.ext
left outer join dbo.arcommnt m on m.comment_code = c.inv_comment_code
left outer join dbo.orders_invoice i on i.order_no = o.order_no and i.order_ext = o.ext
left outer join dbo.arshipv v on v.ship_via_code = o.routing
left outer join dbo.freight_type f on f.kys = o.freight_allow_type
left outer join dbo.arfob fob on fob.fob_code = o.fob
left outer join dbo.arterms t on t.terms_code = o.terms
left outer join dbo.artax tax on tax.tax_code = o.tax_id
left outer join dbo.artax taxd on taxd.tax_code = l.tax_code
where o.invoice_no = 0 and isnull(o.tax_valid_ind,1) = 1 and o.order_no = ' + @ord + ' and o.ext = ' + @ext)


declare @mask varchar(100), @phone varchar(50), @orig_mask varchar(100)
declare @x_order_no int, @x_order_ext int
select @orig_mask = isnull((select mask from masktbl (nolock)
  where lower(mask_name) = 'phone number mask'),'(###) ###-#### Ext. ####')

DECLARE pickcursor CURSOR LOCAL FOR
SELECT distinct o_order_no, o_ext
from #rpt_soaform
OPEN pickcursor
FETCH NEXT FROM pickcursor INTO @x_order_no, @x_order_ext

While @@FETCH_STATUS = 0
begin
select @phone = isnull((select isnull(phone,'')
from orders_all where order_no = @x_order_no and ext = @x_order_ext),'')
if @phone != ''
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
end
if @pos > 0
  select @mask = substring(@mask,1,@pos)

update #rpt_soaform
set o_masked_phone = @mask
where o_order_no = @x_order_no and o_ext = @x_order_ext
FETCH NEXT FROM pickcursor INTO @x_order_no, @x_order_ext
end

close pickcursor
deallocate pickcursor



update #rpt_soaform
set h_currency_mask = h.currency_mask,
h_curr_precision = h.curr_precision,
h_rounding_factor = h.rounding_factor,
h_position = case when h.neg_num_format in (0,1,2,10,15) then 1 when h.neg_num_format in (6,7,9,14) then 2 
  when h.neg_num_format in (5,8,11,16) then 3 else 0 end,
h_neg_num_format = case when h.neg_num_format in (2,3,6,9,10,13) then 1 when h.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
h_symbol = h.symbol,
h_symbol_space = case when h.neg_num_format < 9 then '' when h.neg_num_format in (9,11,14,16) then 'b' else 'a' end
from #rpt_soaform, glcurr_vw h, glco g
where h.currency_code = g.home_currency

select * from #rpt_soaform
order by o_sort_order, o_sort_order2, o_sort_order3
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_soaform] TO [public]
GO
