SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[adm_ep_ins_order]
@cust_code varchar(10),  @req_ship_date datetime,  @cust_po varchar(20),  
@attention varchar(40),  @note varchar(255), @location varchar(10), 
@sold_to_addr1 varchar(40),  @sold_to_addr2 varchar(40),  @sold_to_addr3 varchar(40),  @sold_to_addr4 varchar(40), 
@sold_to_addr5 varchar(40),  @sold_to_addr6 varchar(40), @void_ind int = 0 
as

declare @ord_no int,  @ord_ext int, @rc int
select @ord_no = 0, @rc = 1

select @location = isnull(@location,'')
if @location != ''
begin
  if not exists (select 1 from locations_all where location = @location and isnull(void,'N') != 'V' and location not like 'DROP%')
    select @rc = 2, @location = ''
end
if @location = ''
  return -4

if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
  and ext = 0 and isnull(eprocurement_ind,0) = 1)
begin
  if isnull((select count(*) from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
    and ext = 0 and (status = 'N' or status < 'L') and isnull(eprocurement_ind,0) = 1), 0) > 1
  begin
    return -2
  end

  select @ord_no = order_no,  @ord_ext = 0
  from orders_all 
  where cust_po = @cust_po and cust_code = @cust_code and ext = 0 and (status = 'N' or status < 'L')
    and isnull(eprocurement_ind,0) = 1

  if @@rowcount = 0
  begin
    if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
      and ext = 0 and status in ('P','Q','R') and isnull(eprocurement_ind,0) = 1)
      return -10
    if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
      and ext = 0 and status in ('S','T') and isnull(eprocurement_ind,0) = 1)
      return -11
    if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
      and ext = 0 and status = 'V' and isnull(eprocurement_ind,0) = 1)
      return -12

    return -13
  end

  if @void_ind = 1
  begin
    update orders_all
    set status = 'V', void = 'V', void_date = getdate(), void_who = 'eprocurement'
    where order_no = @ord_no and ext = @ord_ext
  end
  else
  begin
    update orders_all
    set req_ship_date = isnull(@req_ship_date,req_ship_date),
      attention = isnull(@attention,attention),
      location = @location, 
      sold_to_addr1 = @sold_to_addr1, 
      sold_to_addr2 = @sold_to_addr2, 
      sold_to_addr3 = @sold_to_addr3, 
      sold_to_addr4 = @sold_to_addr4, 
      sold_to_addr5 = @sold_to_addr5, 
      sold_to_addr6 = @sold_to_addr6,
      ship_to_name = @sold_to_addr1,
      ship_to_add_1 = @sold_to_addr2,
      ship_to_add_2 = @sold_to_addr3,
      ship_to_add_3 = @sold_to_addr4,
      ship_to_add_4 = @sold_to_addr5,
      ship_to_add_5 = @sold_to_addr6
    where order_no = @ord_no and ext = @ord_ext
  end
end
else
begin
  if @void_ind = 0
  begin

  update next_order_num
  set last_no = last_no + 1
  select @ord_no = last_no from next_order_num

  insert orders_all (
    order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po, 
    who_entered, status, attention, phone, terms, routing, special_instr, invoice_date, total_invoice, 
    total_amt_order, salesperson, tax_id, tax_perc, invoice_no, fob, freight, printed, discount, label_no, 
    cancel_date, new, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5, 
    ship_to_city, ship_to_state, ship_to_zip, ship_to_country, ship_to_region, cash_flag, type, back_ord_flag, 
    freight_allow_pct, route_code, route_no, date_printed, date_transfered, cr_invoice_no, who_picked, note, 
    void, void_who, void_date, changed, remit_key, forwarder_key, freight_to, sales_comm, freight_allow_type, 
    cust_dfpa, location, total_tax, total_discount, f_note, invoice_edi, edi_batch, post_edi_date, blanket, 
    gross_sales, load_no, curr_key, curr_type, curr_factor, bill_to_key, oper_factor, tot_ord_tax, tot_ord_disc, 
    tot_ord_freight, posting_code, rate_type_home, rate_type_oper, reference_code, hold_reason, dest_zone_code, 
    orig_no, orig_ext, tot_tax_incl, process_ctrl_num, batch_code, tot_ord_incl, barcode_status, multiple_flag, 
    so_priority_code, FO_order_no, blanket_amt, user_priority, user_category, from_date, to_date, consolidate_flag,
    proc_inv_no, sold_to_addr1, sold_to_addr2, sold_to_addr3, sold_to_addr4, sold_to_addr5, sold_to_addr6, user_code,
    eprocurement_ind
  )
  select
    @ord_no, 0, customer_code, '', @req_ship_date, @req_ship_date, NULL, getdate(), @cust_po,
    'eprocurement', 'N', @attention, '', terms_code, ship_via_code, NULL, NULL, 0,
    0, salesperson_code, tax_code, 0, 0, fob_code, 0, 'N', 0, 0,
    NULL, NULL, @sold_to_addr1, @sold_to_addr2, @sold_to_addr3, @sold_to_addr4, @sold_to_addr5, @sold_to_addr6,
    '', '', '', country, territory_code, 'N', 'I', ship_complete_flag,
    0, route_code, route_no, NULL, NULL, 0, NULL, @note,
    'N', NULL, NULL, 'N', remit_code, forwarder_code, freight_to_code, 0, NULL, 
    NULL, @location, 0, 0, NULL, 'N', NULL, NULL, 'N', 
    0, 0, nat_cur_code, 0, 1, customer_code, 1, 0, 0, 
    0, posting_code, rate_type_home, rate_type_oper, NULL, NULL, dest_zone_code,
    0, 0, 0, '','',0,NULL,'N',
    so_priority_code, NULL, 0, NULL, NULL, NULL, NULL, consolidated_invoices,
    NULL, @sold_to_addr1, @sold_to_addr2, @sold_to_addr3, @sold_to_addr4, @sold_to_addr5, @sold_to_addr6,'',
    1
  from adm_cust_all
  where customer_code = @cust_code

  if @@rowcount = 0
  begin
    return -6
  end

  update o
  set f_note = isnull(name,'') + '
' + isnull(addr1,'') + '
' + isnull(addr2,'') + '
' + isnull(addr3,'') 
from orders_all o, arfwdr a
where o.order_no = @ord_no and o.ext = 0 and a.kys = o.forwarder_key

  end -- void_ind = 0
end

if @ord_no = 0
begin
  return -1
end

return @rc
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_order] TO [public]
GO
