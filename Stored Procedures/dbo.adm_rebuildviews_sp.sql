SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[adm_rebuildviews_sp]
AS
declare @ext_sec int, @loc_sec int, @tot_sec int, @inter_org int

SELECT @ext_sec = isnull((select extended_security_flag from smcomp_vw (nolock)),0)
select @loc_sec = case when isnull((select loc_security_flag from dmco (nolock)),0) = 0 then -1 else 1 end
select @tot_sec = @ext_sec + @loc_sec

select @inter_org = isnull((select ib_flag from glco),0)

DECLARE @buf varchar(8000)
DECLARE	@buf2  varchar(100)
declare @vw_name varchar(255)

select @vw_name = 'adm_ext_security_is_installed_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
		AS select ' + convert(varchar(20), @tot_sec) + ' sec_level'
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '

----------------------------------------
select @vw_name = 'adm_orgs_with_access_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
'
select @buf = @buf + 'select case when organization_id = spid.org_id then 1 else 0 end curr_org_ind,  
    organization_id    
    from
	('
if @ext_sec = 1 
begin
  select @buf = @buf + ' SELECT ''ALL'', organization_id FROM Organization_all (nolock)
	UNION
	SELECT ''SOME'', organization_id 
	FROM organizationsecurity o (nolock)
	join securitytokendetail td (nolock) on o.security_token = td.security_token AND td.type =4
	join smgrpdet_vw d (nolock) on td.group_id = d.group_id
	join smspiduser_vw v (nolock) on d.domain_username = v.user_name and v.spid = @@spid
	UNION
	SELECT ''SOME'', organization_id FROM Organization_all
			WHERE ( dbo.sm_user_is_administrator_fn()=1)
'
end
else
begin
  select @buf = @buf + '
	SELECT ''SOME'', organization_id FROM Organization_all
'
end

if @inter_org = 0
begin
  select @buf = @buf + 'UNION
    select ''SOME'', '''''
end

select @buf = @buf + ')
    as t(access, organization_id)
    join (select dbo.sm_get_current_org_fn()) as spid(org_id) on 1=1
	where app_name()= ''Epicor Scheduler'' or access = ''SOME'''

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'adm_po_hdr_locs_access_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
'
select @buf = @buf + 
'select t.curr_org_ind, t.organization_id, t.location
from
    (select distinct isnull(r.create_ind,d.create_po_dflt_ind) create_ind, a.curr_org_ind, a.organization_id,
      a.location, isnull(io_create_po_ind,d.create_po_dflt_ind), isnull(spid.org_id,'''')
    from adm_locs_with_access_vw a
    join dmco d (nolock) on 1 = 1
    join (select dbo.sm_get_current_org_fn()) as spid(org_id) on 1=1
	left outer join adm_organization o (nolock) on o.organization_id = spid.org_id
    left outer join adm_po_locorgrel_vw r (nolock) on  r.related_org_id = spid.org_id and a.location = r.location)
    as t(create_ind, curr_org_ind, organization_id, location, io_create_po_ind, user_org_id)
    ' +
case when @tot_sec = -1 then
  'where t.organization_id <> '''''
when @tot_sec in (1,2) then
  'where (isnull(t.io_create_po_ind,0) = 0 and t.organization_id = t.user_org_id)
     or (isnull(t.io_create_po_ind,0) != 0 and t.create_ind > 0)'
when @tot_sec = 0 and @inter_org = 1 then
  'where t.organization_id = t.user_org_id'
else ''
end
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'adm_pomchchg'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select
h.match_ctrl_int,
h.vendor_code,
h.vendor_remit_to,
h.vendor_invoice_no,
h.date_match,
h.printed_flag,
h.vendor_invoice_date,
h.invoice_receive_date,
h.apply_date,
h.aging_date,
h.due_date,
h.discount_date,
h.amt_net,
h.amt_discount,
h.amt_tax,
h.amt_freight,
h.amt_misc,
h.amt_due,
h.match_posted_flag,
h.nat_cur_code,
h.amt_tax_included,
h.trx_type,
h.po_no,
h.location,
h.amt_gross,
h.process_group_num,
h.rate_type_home,
h.rate_type_oper,
h.curr_factor,
h.oper_factor,
h.tax_code,
h.terms_code,
h.one_time_vend_ind,
h.pay_to_addr1,
h.pay_to_addr2,
h.pay_to_addr3,
h.pay_to_addr4,
h.pay_to_addr5,
h.pay_to_addr6,
h.attention_name,
h.attention_phone,
h.amt_nonrecoverable_tax,
h.tax_freight_no_recoverable,
h.amt_nonrecoverable_incl_tax,
h.organization_id,
h.pay_to_city,
h.pay_to_state,
h.pay_to_zip,
h.pay_to_country_cd,
h.tax_valid_ind,
h.pay_to_addr_valid_ind,
h.trx_ctrl_num 
from adm_pomchchg_all h
'

if @tot_sec > -1
  select @buf = @buf + 'join adm_po_hdr_locs_access_vw s (nolock) on s.location = h.location
'

if @ext_sec = 1
  select @buf = @buf + 'left outer join (select distinct match_ctrl_int
  from adm_pomchcdt d (nolock)
  left outer join adm_locs_with_access_vw a (nolock) on a.location = d.location  
  where a.location is null) as d(match_ctrl_int) on d.match_ctrl_int = h.match_ctrl_int
where d.match_ctrl_int is null
'
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'adm_so_hdr_locs_access_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select t.curr_org_ind, t.organization_id, t.location
from
    (select distinct isnull(r.create_ind,d.create_so_dflt_ind) create_ind, a.curr_org_ind, a.organization_id,
      a.location, isnull(io_create_so_ind,d.create_so_dflt_ind), isnull(spid.org_id,'''')
    from adm_locs_with_access_vw a
    join dmco d (nolock) on 1 = 1
    join (select dbo.sm_get_current_org_fn()) as spid(org_id) on 1=1
	left outer join adm_organization o (nolock) on o.organization_id = spid.org_id
    left outer join adm_so_locorgrel_vw r (nolock) on  r.related_org_id = spid.org_id and a.location = r.location)
    as t(create_ind, curr_org_ind, organization_id, location, io_create_so_ind, user_org_id)
    ' +
case when @tot_sec = -1 then
  'where t.organization_id <> '''''
when @tot_sec in (1,2) then
  'where (isnull(t.io_create_so_ind,0) = 0 and t.organization_id = t.user_org_id)
     or (isnull(t.io_create_so_ind,0) != 0 and t.create_ind > 0)'
when @tot_sec = 0 and @inter_org = 1 then
  'where t.organization_id = t.user_org_id'
else ''
end

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'locations'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
l.timestamp,
l.location,
name,
location_type,
addr1,
addr2,
addr3,
addr4,
addr5,
addr_sort1,
addr_sort2,
addr_sort3,
phone,
contact_name,
consign_customer_code,
consign_vendor_code,
aracct_code,
zone_code,
void,
void_who,
void_date,
note,
apacct_code,
dflt_recv_bin,
country_code,
harbour,
bundesland,
department,
l.organization_id,
city,
state,
zip
from locations_all l
'

if @tot_sec > -1
begin
  select @buf = @buf + 'join adm_locs_with_access_vw a (nolock) on  a.location = l.location'
end
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'orders'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
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
o.remit_key,
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
o.consolidate_flag,
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
o.eprocurement_ind,
o.sold_to,
o.sopick_ctrl_num,
o.organization_id,
o.internal_so_ind,
o.ship_to_country_cd,
o.sold_to_city,
o.sold_to_state,
o.sold_to_zip,
o.sold_to_country_cd ,
o.tax_valid_ind ,
o.addr_valid_ind
from orders_all o
'
if @tot_sec > -1
select @buf = @buf + 'join locations l (nolock) on l.location = o.location
'

if @ext_sec = 1
select @buf = @buf + 'left outer join (select distinct order_no, order_ext
  from ord_list d (nolock)
  left outer join adm_locs_with_access_vw a (nolock) on a.location = d.location  
  where a.location is null) as d(order_no, ext) on d.order_no = o.order_no and d.ext = o.ext
where d.order_no is null
'
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'orders_posting_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
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
o.remit_key,
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
o.consolidate_flag,
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
o.eprocurement_ind,
o.sold_to,
o.sopick_ctrl_num,
o.organization_id,
o.ship_to_country_cd,
o.sold_to_city,
o.sold_to_state,
o.sold_to_zip,
o.sold_to_country_cd ,
o.tax_valid_ind ,
o.addr_valid_ind
from orders_all o
'

if @tot_sec > -1
select @buf = @buf + 'join locations l (nolock) on l.location = o.location
'

if @ext_sec = 1
select @buf = @buf + 'left outer join (select distinct order_no, order_ext
  from ord_list d (nolock)
  left outer join adm_locs_with_access_vw a (nolock) on a.location = d.location  
  where a.location is null) as d(order_no, ext) on d.order_no = o.order_no and d.ext = o.ext
where d.order_no is null
'

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'orders_shipping_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
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
o.remit_key,
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
o.consolidate_flag,
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
o.eprocurement_ind,
o.sold_to,
o.sopick_ctrl_num,
o.organization_id,
' +
case when @tot_sec > -1 then 'case when a.location is null then 1 else 0 end protect_line,'
else '0 protect_line,' end + '
o.ship_to_country_cd,
o.sold_to_city,
o.sold_to_state,
o.sold_to_zip,
o.sold_to_country_cd ,
o.tax_valid_ind ,
o.addr_valid_ind
from orders_all o
'

if @tot_sec > -1 
  select @buf = @buf + 'left outer join adm_locs_with_access_vw a (nolock) on a.location = o.location
'

if @ext_sec = 1
  select @buf = @buf + 'join (select distinct order_no, order_ext
from ord_list d (nolock)
join adm_locs_with_access_vw a (nolock) on  a.location = d.location)
as d(order_no, order_ext) on d.order_no = o.order_no and d.order_ext = o.ext
'

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'purchase'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select
p.po_no,
p.status,
p.po_type,
p.printed,
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
p.attn,
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
p.freight_inv_no,
p.void,
p.void_who,
p.void_date,
p.note,
p.po_key,
p.po_ext,
p.curr_key,
p.curr_type,
p.curr_factor,
p.buyer,
p.location,
p.prod_no,
p.oper_factor,
p.hold_reason,
p.phone,
p.total_tax,
p.rate_type_home,
p.rate_type_oper,
p.reference_code,
p.posting_code,
p.user_code,
p.expedite_flag,
p.vend_order_no,
p.requested_by,
p.approved_by,
p.user_category,
p.blanket_flag,
p.date_blnk_from,
p.date_blnk_to,
p.amt_blnk_limit,
p.etransmit_status,
p.approval_status,
p.etransmit_date,
p.eprocurement_last_sent_date,
p.eprocurement_last_recv_date,
p.user_def_fld1,
p.user_def_fld2,
p.user_def_fld3,
p.user_def_fld4,
p.user_def_fld5,
p.user_def_fld6,
p.user_def_fld7,
p.user_def_fld8,
p.user_def_fld9,
p.user_def_fld10,
p.user_def_fld11,
p.user_def_fld12,
p.one_time_vend_ind,
p.vendor_addr1,
p.vendor_addr2,
p.vendor_addr3,
p.vendor_addr4,
p.vendor_addr5,
p.vendor_addr6,
p.organization_id,
p.ship_to_organization_id,
p.internal_po_ind,
p.ship_country_cd,
p.vendor_city,
p.vendor_state,
p.vendor_zip,
p.vendor_country_cd,
p.tax_valid_ind ,
p.addr_valid_ind ,
p.vendor_addr_valid_ind,
p.proc_po_no,
p.approval_code,
p.approval_flag
from purchase_all p
'
if @tot_sec > -1
  select @buf = @buf + 'join adm_locs_with_access_vw s on s.location = p.location
join adm_locs_with_access_vw s1 on s1.location = p.ship_to_no
'

if @ext_sec = 1
  select @buf = @buf + 'left outer join (select distinct po_no
  from pur_list l (nolock)
  left outer join adm_locs_with_access_vw s on s.location = l.receiving_loc
  where s.location is null) as l (po_no) on l.po_no = p.po_no
where l.po_no is null
'

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'rtv'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select
r.rtv_no,
r.vendor_no,
r.location,
r.status,
r.printed,
r.date_of_order,
r.date_order_due,
r.vend_rma_no,
r.ship_to_no,
r.ship_name,
r.ship_address1,
r.ship_address2,
r.ship_address3,
r.ship_address4,
r.ship_address5,
r.ship_city,
r.ship_state,
r.ship_zip,
r.ship_via,
r.fob,
r.terms,
r.attn,
r.rtv_type,
r.who_entered,
r.total_amt_order,
r.restock_fee,
r.freight,
r.date_to_pay,
r.vend_inv_no,
r.freight_flag,
r.freight_vendor,
r.freight_inv_no,
r.void,
r.void_who,
r.void_date,
r.post_to_ap,
r.note,
r.tax_code,
r.tax_amt,
r.currency_key,
r.curr_factor,
r.rate_type_home,
r.rate_type_oper,
r.oper_factor,
r.posting_code,
r.apply_date,
r.doc_date,
r.match_ctrl_int,
r.amt_tax_included,
r.organization_id,
r.ship_to_country_cd ,
r.tax_valid_ind ,
r.addr_valid_ind
from rtv_all r
'
if @tot_sec > -1
  select @buf = @buf + 'join adm_po_hdr_locs_access_vw s (nolock) on  s.location = r.location
'
if @ext_sec = 1
  select @buf = @buf + 'left outer join (select distinct rtv_no
  from rtv_list d (nolock)
  left outer join adm_locs_with_access_vw a (nolock) on a.location = d.location  
  where a.location is null) as d(rtv_no) on d.rtv_no = r.rtv_no
where d.rtv_no is null
'

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)


----------------------------------------
select @vw_name = 'purchase_entry_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select
p.po_no,
p.status,
p.po_type,
p.printed,
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
p.attn,
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
p.freight_inv_no,
p.void,
p.void_who,
p.void_date,
p.note,
p.po_key,
p.po_ext,
p.curr_key,
p.curr_type,
p.curr_factor,
p.buyer,
p.location,
p.prod_no,
p.oper_factor,
p.hold_reason,
p.phone,
p.total_tax,
p.rate_type_home,
p.rate_type_oper,
p.reference_code,
p.posting_code,
p.user_code,
p.expedite_flag,
p.vend_order_no,
p.requested_by,
p.approved_by,
p.user_category,
p.blanket_flag,
p.date_blnk_from,
p.date_blnk_to,
p.amt_blnk_limit,
p.etransmit_status,
p.approval_status,
p.etransmit_date,
p.eprocurement_last_sent_date,
p.eprocurement_last_recv_date,
p.user_def_fld1,
p.user_def_fld2,
p.user_def_fld3,
p.user_def_fld4,
p.user_def_fld5,
p.user_def_fld6,
p.user_def_fld7,
p.user_def_fld8,
p.user_def_fld9,
p.user_def_fld10,
p.user_def_fld11,
p.user_def_fld12,
p.one_time_vend_ind,
p.vendor_addr1,
p.vendor_addr2,
p.vendor_addr3,
p.vendor_addr4,
p.vendor_addr5,
p.vendor_addr6,
p.organization_id,
p.ship_to_organization_id,
p.ship_country_cd,
p.vendor_city,
p.vendor_state,
p.vendor_zip,
p.vendor_country_cd,
p.tax_valid_ind ,
p.addr_valid_ind ,
p.vendor_addr_valid_ind,
p.proc_po_no,
p.approval_code,
p.approval_flag
from purchase p
'
if @tot_sec > -1 
  select @buf = @buf + 'join adm_po_hdr_locs_access_vw s (nolock) on s.location = p.location
'

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'purchase_rcvg_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select
p.po_no,
p.status,
p.po_type,
p.printed,
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
p.attn,
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
p.freight_inv_no,
p.void,
p.void_who,
p.void_date,
p.note,
p.po_key,
p.po_ext,
p.curr_key,
p.curr_type,
p.curr_factor,
p.buyer,
p.location,
p.prod_no,
p.oper_factor,
p.hold_reason,
p.phone,
p.total_tax,
p.rate_type_home,
p.rate_type_oper,
p.reference_code,
p.posting_code,
p.user_code,
p.expedite_flag,
p.vend_order_no,
p.requested_by,
p.approved_by,
p.user_category,
p.blanket_flag,
p.date_blnk_from,
p.date_blnk_to,
p.amt_blnk_limit,
p.etransmit_status,
p.approval_status,
p.etransmit_date,
p.eprocurement_last_sent_date,
p.eprocurement_last_recv_date,
p.user_def_fld1,
p.user_def_fld2,
p.user_def_fld3,
p.user_def_fld4,
p.user_def_fld5,
p.user_def_fld6,
p.user_def_fld7,
p.user_def_fld8,
p.user_def_fld9,
p.user_def_fld10,
p.user_def_fld11,
p.user_def_fld12,
p.one_time_vend_ind,
p.vendor_addr1,
p.vendor_addr2,
p.vendor_addr3,
p.vendor_addr4,
p.vendor_addr5,
p.vendor_addr6,
p.organization_id,
p.ship_to_organization_id,
p.ship_country_cd,
p.vendor_city,
p.vendor_state,
p.vendor_zip,
p.vendor_country_cd,
p.tax_valid_ind ,
p.addr_valid_ind ,
p.vendor_addr_valid_ind,
p.proc_po_no,
p.approval_code,
p.approval_flag
from purchase_all p
where 
' + case when @tot_sec > -1 then 'p.po_no in (select po_no from pur_list l (nolock)
join adm_locs_with_access_vw s (nolock) on s.location = l.receiving_loc)
and 
' else '' end + 
'isnull(p.approval_flag,0) = 0
'

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'orders_entry_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
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
o.remit_key,
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
o.consolidate_flag,
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
o.eprocurement_ind,
o.sold_to,
o.sopick_ctrl_num,
o.organization_id,
o.ship_to_country_cd,
o.sold_to_city,
o.sold_to_state,
o.sold_to_zip,
o.sold_to_country_cd ,
o.tax_valid_ind ,
o.addr_valid_ind
from orders o
' + case when @tot_sec > -1 then 'join adm_so_hdr_locs_access_vw s (nolock) on s.location = o.location'
else '' end
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'ord_list_ship_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
l.order_no,
l.order_ext,
l.line_no,
l.location,
l.part_no,
l.description,
l.time_entered,
l.ordered,
l.shipped,
l.price,
l.price_type,
l.note,
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
l.orig_part_no,
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
l.cust_po,
l.organization_id,
l.picked_dt,
l.who_picked_id,
l.printed_dt,
l.who_unpicked_id,
l.unpicked_dt,
' + case when @tot_sec = -1 then '0 protect_line'
else
'case when a.location is null then 1 else 0 end protect_line' end + '
from ord_list l
' + case when @tot_sec > -1 then 
'left outer join adm_locs_with_access_vw a (nolock) on  a.location = l.location'
else '' end
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'locations_hdr_vw'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
l.timestamp,
l.location,
name,
location_type,
addr1,
addr2,
addr3,
addr4,
addr5,
addr_sort1,
addr_sort2,
addr_sort3,
phone,
contact_name,
consign_customer_code,
consign_vendor_code,
aracct_code,
zone_code,
void,
void_who,
void_date,
note,
apacct_code,
dflt_recv_bin,
country_code,
harbour,
bundesland,
department,
l.organization_id,
valid.module,
o.io_use_po_ind,
o.io_use_so_ind,
o.io_use_xfer_ind,
o.io_create_po_ind,
o.io_create_so_ind,
o.use_ext_vend_ind,
l.city,
l.state,
l.zip,
s.curr_org_ind
from locations_all l (nolock)
join adm_locs_with_access_vw s (nolock) on s.location = l.location
left outer join adm_organization o (nolock) on l.organization_id = o.organization_id
join (
' + 
case when @tot_sec = -1 then
'select  ''po'' module 
 UNION
select  ''cm'' module 
 UNION
select  ''soe'' module 
UNION
select  ''match'' module 
UNION
select  ''xfr'' module 
) as valid ( module) on 1=1'
else
'select location, ''po'' module from adm_po_hdr_locs_access_vw o (nolock)
 UNION
select location, ''cm'' module from adm_so_hdr_locs_access_vw o (nolock)
 UNION
select location, ''soe'' module from adm_so_hdr_locs_access_vw o (nolock)
UNION
select location, ''match'' module from adm_po_hdr_locs_access_vw o (nolock)
UNION
select location, ''xfr'' module from adm_locs_with_access_vw o (nolock)
) as valid (location, module) on l.location = valid.location
'
end

EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

----------------------------------------
select @vw_name = 'load_master'
SELECT @buf =	'IF EXISTS (SELECT name FROM sysobjects             
	WHERE name = ''' + @vw_name + ''' )  DROP view ' + @vw_name
EXEC (@buf)

SELECT @buf =	'CREATE view ' + @vw_name + '
AS
select 
m.load_no,
m.location,
m.truck_no,
m.trailer_no,
m.driver_key,
m.driver_name,
m.pro_number,
m.routing,
m.stop_count,
m.total_miles,
m.sch_ship_date,
m.date_shipped,
m.status,
m.orig_status,
m.hold_reason,
m.contact_name,
m.contact_phone,
m.invoice_type,
m.create_who_nm,
m.user_hold_who_nm,
m.credit_hold_who_nm,
m.picked_who_nm,
m.shipped_who_nm,
m.posted_who_nm,
m.create_dt,
m.process_ctrl_num,
m.user_hold_dt,
m.credit_hold_dt,
m.picked_dt,
m.posted_dt,
m.organization_id
from load_master_all m
' + case when @tot_sec <> -1 then
'join adm_locs_with_access_vw a (nolock) on a.location = m.location' 
else '' end
EXEC (@buf)

SELECT @buf ='	GRANT SELECT  ON ' + @vw_name + ' TO PUBLIC '
EXEC (@buf)

GO
GRANT EXECUTE ON  [dbo].[adm_rebuildviews_sp] TO [public]
GO
