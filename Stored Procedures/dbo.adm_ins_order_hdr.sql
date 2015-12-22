SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ins_order_hdr] @mode int, @row_id int, @ord_no int output, @ext int output
as
-- mode = 1 - regular order
-- mode = 2 - blanket release header

declare @rc int
declare @precision int, @home_override_flag int, @oper_override_flag int,
  @curr_code varchar(8), @home_currency varchar(8), @oper_currency varchar(8),
  @rate_type_home varchar(8), @cust_code varchar(10),
  @rate_type_oper varchar(8), @result int, @date_applied int,
  @divide_flag_h smallint, @divide_flag_o smallint,
  @home_rate decimal(20,8), @oper_rate decimal(20,8),
  @status char(1)


if @mode = 1
begin
  select @ord_no = 0, @ext = 0, @rc = 1
  update next_order_num
  set last_no = last_no + 1
  select @ord_no = last_no from next_order_num

  select @curr_code = curr_code,
    @cust_code = customer_code,
    @date_applied = datediff(day,'01/01/1900',getdate()) + 693596
  from #ins_order
  where row_id = @row_id
 
  SELECT @home_currency = home_currency,	
    @oper_currency = oper_currency 
  FROM glco (nolock)	

  select @precision = curr_precision
  from glcurr_vw (nolock)
  where currency_code = @curr_code

  select @rate_type_home = rate_type_home, @rate_type_oper = rate_type_oper
  from adm_cust_all (nolock)
  where customer_code = @cust_code

  EXEC @result = adm_mccurate_sp
    @date_applied,	@curr_code,	@home_currency,		
    @rate_type_home, @home_rate OUTPUT, 0, @divide_flag_h	OUTPUT
		
    IF ( @result != 0 ) SELECT @home_rate = 0

  EXEC @result = adm_mccurate_sp
    @date_applied, @curr_code, @oper_currency,		
    @rate_type_oper, @oper_rate OUTPUT, 0, @divide_flag_o OUTPUT
					
    IF ( @result != 0 ) SELECT @oper_rate = 0


  insert orders_all (
    order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po, 
    who_entered, status, attention, phone, terms, routing, special_instr, invoice_date, total_invoice, 
    total_amt_order, salesperson, tax_id, tax_perc, invoice_no, fob, freight, printed, discount, label_no, 
    cancel_date, new, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5, 
    ship_to_city, ship_to_state, ship_to_zip, ship_to_country_cd, ship_to_region, cash_flag, type, back_ord_flag, 
    freight_allow_pct, route_code, route_no, date_printed, date_transfered, cr_invoice_no, who_picked, note, 
    void, void_who, void_date, changed, remit_key, forwarder_key, freight_to, sales_comm, freight_allow_type, 
    cust_dfpa, location, total_tax, total_discount, f_note, invoice_edi, edi_batch, post_edi_date, blanket, 
    gross_sales, load_no, curr_key, curr_type, curr_factor, bill_to_key, oper_factor, tot_ord_tax, tot_ord_disc, 
    tot_ord_freight, posting_code, rate_type_home, rate_type_oper, reference_code, hold_reason, dest_zone_code, 
    orig_no, orig_ext, tot_tax_incl, process_ctrl_num, batch_code, tot_ord_incl, barcode_status, multiple_flag, 
    so_priority_code, FO_order_no, blanket_amt, user_priority, user_category, from_date, to_date, consolidate_flag,
    proc_inv_no, sold_to_addr1, sold_to_addr2, sold_to_addr3, sold_to_addr4, sold_to_addr5, sold_to_addr6, user_code,
    eprocurement_ind, sold_to_city, sold_to_state,
    sold_to_zip, sold_to_country_cd, tax_valid_ind, addr_valid_ind
  )
  select
    @ord_no, 0, t.customer_code, t.ship_to, t.req_ship_date, t.sch_ship_date, NULL, getdate(), t.cust_po,
    host_name(), 
    case when t.hold_reason is not null then 'A' else 'N' end, 
    isnull(t.attention,''), isnull(t.phone,''), t.terms_code, t.routing, isnull(t.si,''), NULL, 0,
    0, isnull(t.salesperson,''), t.tax_id, 0, 0, t.fob, 0, 'N', 0, 0,
    NULL, NULL, t.ship_to_name, t.addr1,t.addr2,t.addr3,t.addr4,t.addr5,
    t.city, t.state, t.zip, t.country_cd, isnull(t.ship_to_region,''), 'N', 'I', t.back_ord_flag,
    0, isnull(route_code,''), route_no, NULL, NULL, 0, NULL, isnull(t.note,''),
    'N', NULL, NULL, 'N', t.remit, t.forwarder, t.freight_to, 0, t.freight_allow_type, 
    NULL, t.location, 0, 0, '', 'N', NULL, NULL, 'N', 
    0, 0, t.curr_code, 0, @home_rate, t.customer_code, @oper_rate, 0, 0, 
    t.tot_freight, t.posting_code, rate_type_home, rate_type_oper, NULL, isnull(t.hold_reason,''), t.dest_zone_code,
    0, 0, 0, '','0',0,NULL,'N',
    a.so_priority_code, NULL, 0, '', '', NULL, NULL, a.consolidated_invoices,
    '', NULL,NULL,NULL,NULL,NULL,NULL,'',0, NULL, NULL, NULL, NULL, 0, 0
  from #ins_order t, adm_cust_all a
  where a.customer_code = t.customer_code and t.row_id  = @row_id

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
end

if @mode = 2
begin
  declare @sch_ship_date datetime

  select @sch_ship_date = sch_ship_date 
  from #ins_ord_list_rel
  where rel_row_id = @row_id

  select @ext = isnull((select max(ext) from orders_all where order_no = @ord_no and ext > 0 and blanket = 'Y' and sch_ship_date = @sch_ship_date
    and status < 'S'),0)
  if @ext > 0
  begin
    return 2    
  end
  else
    select @ext = isnull((select max(ext) from orders_all where order_no = @ord_no),0) + 1

  select @curr_code = curr_key,
    @cust_code = cust_code,
    @rate_type_home = rate_type_home, @rate_type_oper = rate_type_oper,
    @date_applied = datediff(day,'01/01/1900',getdate()) + 693596,
    @status = status
  from orders_all
  where order_no = @ord_no and ext = 0
 
  SELECT @home_currency = home_currency,	
    @oper_currency = oper_currency 
  FROM glco (nolock)	

  select @precision = curr_precision
  from glcurr_vw (nolock)
  where currency_code = @curr_code

  EXEC @result = adm_mccurate_sp
    @date_applied,	@curr_code,	@home_currency,		
    @rate_type_home, @home_rate OUTPUT, 0, @divide_flag_h	OUTPUT
		
    IF ( @result != 0 ) SELECT @home_rate = 0

  EXEC @result = adm_mccurate_sp
    @date_applied, @curr_code, @oper_currency,		
    @rate_type_oper, @oper_rate OUTPUT, 0, @divide_flag_o OUTPUT
					
    IF ( @result != 0 ) SELECT @oper_rate = 0

  if exists (select 1 from orders_all where order_no = @ord_no and ext = 0 and status not in ('M','N','A'))
    return -1
  else
  begin
    update orders_all
    set status = 'M'
    where order_no = @ord_no and ext = 0 and status = 'N'
  end

  update orders_all
  set from_date =  case when getdate() >= @sch_ship_date then @sch_ship_date else getdate() end,
    to_date =   case when getdate() <= @sch_ship_date then @sch_ship_date else getdate() end,
    blanket = 'Y',
    orig_no = @ord_no,
    orig_ext = 0
  where order_no = @ord_no and ext = 0

  if @@error <> 0
  begin
    return -2
  end

  if @status = 'M'
    select @status = 'N'

  insert orders_all (
    order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po, 
    who_entered, status, attention, phone, terms, routing, special_instr, invoice_date, total_invoice, 
    total_amt_order, salesperson, tax_id, tax_perc, invoice_no, fob, freight, printed, discount, label_no, 
    cancel_date, new, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5, 
    ship_to_city, ship_to_state, ship_to_zip, ship_to_country_cd, ship_to_region, cash_flag, type, back_ord_flag, 
    freight_allow_pct, route_code, route_no, date_printed, date_transfered, cr_invoice_no, who_picked, note, 
    void, void_who, void_date, changed, remit_key, forwarder_key, freight_to, sales_comm, freight_allow_type, 
    cust_dfpa, location, total_tax, total_discount, f_note, invoice_edi, edi_batch, post_edi_date, blanket, 
    gross_sales, load_no, curr_key, curr_type, curr_factor, bill_to_key, oper_factor, tot_ord_tax, tot_ord_disc, 
    tot_ord_freight, posting_code, rate_type_home, rate_type_oper, reference_code, hold_reason, dest_zone_code, 
    orig_no, orig_ext, tot_tax_incl, process_ctrl_num, batch_code, tot_ord_incl, barcode_status, multiple_flag, 
    so_priority_code, FO_order_no, blanket_amt, user_priority, user_category, from_date, to_date, consolidate_flag,
    proc_inv_no, sold_to_addr1, sold_to_addr2, sold_to_addr3, sold_to_addr4, sold_to_addr5, sold_to_addr6, user_code,
    eprocurement_ind, sold_to_city, sold_to_state,
    sold_to_zip, sold_to_country_cd, tax_valid_ind, addr_valid_ind
  )
  select
    order_no, @ext, cust_code, ship_to, @sch_ship_date, @sch_ship_date, NULL, getdate(), cust_po, 
    host_name(), @status, attention, phone, terms, routing, special_instr, NULL, 0, 
    0, salesperson, tax_id, tax_perc, 0, fob, 0, 'N', discount, 0, 
    cancel_date, new, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5, 
    ship_to_city, ship_to_state, ship_to_zip, ship_to_country_cd, ship_to_region, cash_flag, type, back_ord_flag, 
    freight_allow_pct, route_code, route_no, NULL, NULL, 0, NULL, note, 
    'N', NULL, NULL, 'N', remit_key, forwarder_key, freight_to, sales_comm, freight_allow_type, 
    cust_dfpa, location, 0, 0, f_note, invoice_edi, edi_batch, post_edi_date, 'Y', 
    gross_sales, 0, curr_key, curr_type, @home_rate, bill_to_key, @oper_rate, 0, 0, 
    tot_ord_freight, posting_code, rate_type_home, rate_type_oper, reference_code, hold_reason, dest_zone_code, 
    @ord_no, 0, tot_tax_incl, process_ctrl_num, batch_code, tot_ord_incl, barcode_status, multiple_flag, 
    so_priority_code, FO_order_no, blanket_amt, user_priority, user_category, from_date, to_date, consolidate_flag,
    proc_inv_no, sold_to_addr1, sold_to_addr2, sold_to_addr3, sold_to_addr4, sold_to_addr5, sold_to_addr6, user_code,
    eprocurement_ind, sold_to_city, sold_to_state, sold_to_zip, sold_to_country_cd, tax_valid_ind, addr_valid_ind
  from orders_all o
  where o.order_no = @ord_no and o.ext = 0

  if @@rowcount = 0
  begin
    return -3
  end
 
end

return 1
GO
GRANT EXECUTE ON  [dbo].[adm_ins_order_hdr] TO [public]
GO
