SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE VIEW [dbo].[adm_req_orders_vw]
	AS
select 
oc.organization_id vendor_org_id,
o.organization_name vendor_org_name,
isnull(oc.customer_code,'') customer_code,
isnull(l.shipto_name,'') shipto_name,
isnull(l.addr1,'') addr1,
isnull(l.addr2,'') addr2,
isnull(l.addr3,'') addr3,
isnull(l.addr4,'') addr4,
isnull(l.addr5,'') addr5,
isnull(pr.group_no,0) group_no,
convert(char(10),isnull(oc.customer_code,'')) + 
convert(char(40),isnull(l.shipto_name,'')) + 
convert(char(40),isnull(l.addr1,'')) + 
convert(char(40),isnull(l.addr2,'')) + 
convert(char(40),isnull(l.addr3,'')) + 
convert(char(40),isnull(l.addr4,'')) + 
convert(char(40),isnull(l.addr5,'')) + convert(varchar(10),p.curr_key) cust_sort,
convert(char(30),l.part_no) part_sort,
p.po_no cust_po,
l.part_no cust_part,
l.orig_part_type,
case when isnull(l.vend_sku,'') = '' then l.part_no else l.vend_sku end vend_sku,
l.description,
l.curr_cost,
l.unit_measure,
l.tax_code ,
l.line,
r.release_date,
r.due_date,
r.quantity,
r.conv_factor,
r.row_id rel_row_id,
co.organization_name cust_org_name,
p.curr_key,
pr.row_id pr_row_id,
pr.ordered pr_ordered,
pr.sch_ship_date pr_sch_ship_date,
isnull(pr.list_ind,0) pr_list_ind ,
isnull(pr.hdr_ind,0) pr_hdr_ind,
pr.part_no pr_part_no,
isnull(pr.order_flag,'NNN') pr_order_flag,
isnull(pr.o_back_ord_flag,case isnull(cust.ship_complete_flag,0) when 0 then 0 when 1 then 1 when 2 then 2 else 0 end) pr_o_back_ord_flag,
pr.o_location pr_o_location,
isnull(pr.o_req_ship_date,r.release_date) pr_o_req_ship_date,
isnull(pr.o_sch_ship_date,r.release_date) pr_o_sch_ship_date,
isnull(pr.o_note,cust.note) pr_o_note,
isnull(pr.o_si,cust.special_instr) pr_o_si,
dbo.adm_get_locations_org_fn(pr.o_location) pr_o_organization_id,
dbo.adm_get_locations_org_fn(pr.location) pr_l_organization_id,
pr.part_type pr_part_type,
pr.uom pr_uom,
pr.location pr_location,
pr.description pr_description,
pr.price pr_price,
pr.price_type pr_price_type,
pr.discount pr_discount,
pr.back_ord_flag pr_back_ord_flag,
pr.note pr_note,
pr.create_po_ind pr_create_po_ind,
pr.gl_rev_acct pr_gl_rev_acct,
pr.tax_code pr_tax_code,
pr.reference_code pr_reference_code,
isnull(pr.o_tax_id,cust.tax_code) pr_o_tax_id,
pr.conv_factor pr_conv_factor,
isnull(pr.o_routing,arouting.ship_via_code) pr_o_routing,
isnull(pr.o_fob,isnull(af.fob_code ,cust.fob_code)) pr_o_fob,
isnull(pr.o_forwarder,cust.forwarder_code) pr_o_forwarder,
isnull(pr.o_freight_to,cust.freight_to_code) pr_o_freight_to,
pr.o_freight_allow_type pr_o_freight_allow_type,
isnull(pr.o_salesperson,cust.salesperson_code) pr_o_salesperson,
isnull(pr.o_ship_to_region,cust.territory_code) pr_o_ship_to_region,
isnull(pr.o_posting_code,cust.posting_code) pr_o_posting_code,
isnull(pr.o_remit,cust.remit_code) pr_o_remit,
isnull(pr.o_terms_code,cust.terms_code) pr_o_terms_code,
isnull(pr.o_dest_zone_code,cust.dest_zone_code) pr_o_dest_zone_code,
pr.o_hold_reason pr_o_hold_reason,
isnull(pr.o_attention,cust.contact_name) pr_o_attention,
isnull(pr.o_phone,cust.contact_phone) pr_o_phone,
pr.o_tot_freight pr_o_tot_freight,
pr.l_ordered pr_l_ordered,
cust.rate_type_home rate_type_home,
cust.rate_type_oper rate_type_oper,
cust.price_level price_level,
l.city ,
l.state ,
l.zip ,
l.country_cd ,
isnull(l.addr_valid_ind,1) addr_valid_ind,
p.curr_factor

from purchase p (nolock)
join adm_orgvendrel ov (nolock) on p.vendor_no = ov.vendor_code and ov.use_ind = 1
join adm_orgcustrel oc (nolock) on ov.organization_id = oc.related_org_id 
  and ov.related_org_id = oc.organization_id and oc.use_ind = 1 
join pur_list l (nolock) on l.po_no = p.po_no 
join releases r (nolock) on l.po_no = r.po_no and l.line = r.po_line and l.part_no = r.part_no
  and isnull(r.int_order_no,0) = 0
join organization_vw o (nolock) on o.organization_id = oc.organization_id 
join Organization_all co (nolock) on co.organization_id = oc.related_org_id
left outer join po_auto_order_rel pr (nolock) on r.row_id = pr.releases_row_id
join adm_cust cust (nolock) on oc.customer_code = cust.customer_code
left outer join arfob af (nolock) on af.fob_code = p.fob
left outer join arshipv arouting (nolock) on arouting.ship_via_code = p.ship_via
where isnull(p.internal_po_ind,0) = 1 and p.status != 'C'
and isnull(p.approval_flag,0) = 0
--and oc.organization_id = dbo.sm_get_current_org_fn()
GO
GRANT REFERENCES ON  [dbo].[adm_req_orders_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_req_orders_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_req_orders_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_req_orders_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_req_orders_vw] TO [public]
GO
