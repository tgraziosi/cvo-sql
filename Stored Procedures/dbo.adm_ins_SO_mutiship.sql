SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
      
/*                                                            
               Confidential Information                        
    Limited Distribution of Authorized Persons Only             
    Created 2001 and Protected as Unpublished Work             
          Under the U.S. Copyright Act of 1976                  
 Copyright (c) 2001 Epicor Software Corporation, 2001          
                  All Rights Reserved                          
*/                                                      
      
      
      
      
      
      
      
       
      
CREATE PROCEDURE [dbo].[adm_ins_SO_mutiship] (@order_no int)      
AS       
      
declare @ord_no int      
      
      
      
      
      
      
  insert orders ( order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po,       
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
   ship_to_country_cd, sold_to, sold_to_country_cd ,sold_to_zip, sold_to_state, sold_to_city      
     )      
  select distinct      
   ord.order_no, (SELECT (ISNULL(max(ORD2.ext),0) + 1) FROM orders ORD2 WHERE ORD2.order_no = ord.order_no),      
   ord.cust_code, tempd.ShipTo, ord.req_ship_date, ord.sch_ship_date, ord.date_shipped, convert(varchar(20),GETDATE(), 101), ord.cust_po,      
       ord.who_entered, 'N', adm.attention_name, adm.attention_phone, ord.terms, ord.routing, adm.special_instr, ord.invoice_date, ord.total_invoice,      
       ord.total_amt_order, ord.salesperson, ord.tax_id, ord.tax_perc, ord.invoice_no, tempd.Fob, ord.freight, ord.printed, ord.discount, ord.label_no,      
       ord.cancel_date, ord.new, adm.ship_to_name, adm.addr1, adm.addr2, adm.addr3, adm.addr4, adm.addr5,       
   adm.city, adm.state, adm.postal_code, adm.country_code, tempd.ShipToRegion, ord.cash_flag, ord.type, ord.back_ord_flag,       
   ord.freight_allow_pct, ord.route_code, ord.route_no, ord.date_printed, ord.date_transfered, ord.cr_invoice_no, ord.who_picked, ord.note,       
   ord.void, ord.void_who, ord.void_date, ord.changed, ord.remit_key, tempd.Forwarder, ord.freight_to, ord.sales_comm, ord.freight_allow_type,       
   ord.cust_dfpa, ord.location, ord.total_tax, ord.total_discount, ord.f_note, ord.invoice_edi, ord.edi_batch, ord.post_edi_date, 'N',       
   ord.gross_sales, ord.load_no, ord.curr_key, ord.curr_type, ord.curr_factor, ord.bill_to_key, ord.oper_factor, ord.tot_ord_tax, ord.tot_ord_disc,       
   ord.tot_ord_freight, ord.posting_code, ord.rate_type_home, ord.rate_type_oper, ord.reference_code, ord.hold_reason, tempd.DestZone,       
   ord.orig_no, ord.orig_ext, ord.tot_tax_incl, ord.process_ctrl_num, ord.batch_code, ord.tot_ord_incl, ord.barcode_status, ord.multiple_flag,       
   ord.so_priority_code, ord.FO_order_no, 0, ord.user_priority, ord.user_category, ord.from_date, ord.to_date, ord.consolidate_flag,      
   ord.proc_inv_no, ord.sold_to_addr1, ord.sold_to_addr2, ord.sold_to_addr3, ord.sold_to_addr4, ord.sold_to_addr5, ord.sold_to_addr6, '',      
   ord.ship_to_country_cd, ord.sold_to, ord.sold_to_country_cd, ord.sold_to_zip, ord.sold_to_state, ord.sold_to_city      
  from orders ord      
  inner join CVO_TempSO temp ON ord.order_no = temp.NewSO      
  inner join CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber      
  inner join adm_shipto_all adm (NOLOCK) ON adm.ship_to_code = temp.ShipTo      
  where ord.order_no = @order_no      
  AND temp.ShipTo <> tempd.ShipTo AND adm.customer_code = ord.cust_code      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
  insert orders ( order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po,       
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
   ship_to_country_cd, sold_to, sold_to_country_cd ,sold_to_zip, sold_to_state, sold_to_city      
     )       
  select distinct      
   ord.order_no, (SELECT (ISNULL(max(ORD2.ext),0) + 1) FROM orders ORD2 WHERE ORD2.order_no = ord.order_no),       
   ord.cust_code, tempd.ShipTo, ord.req_ship_date, ord.sch_ship_date, ord.date_shipped, convert(varchar(20),GETDATE(), 101), ord.cust_po,      
       ord.who_entered, 'N', ord.attention, ord.phone, ord.terms, ord.routing, ord.special_instr, ord.invoice_date, ord.total_invoice,      
       ord.total_amt_order, ord.salesperson, ord.tax_id, ord.tax_perc, ord.invoice_no, tempd.Fob, ord.freight, ord.printed, ord.discount, ord.label_no,      
       ord.cancel_date, ord.new, ord.ship_to_name, ord.ship_to_add_1, ord.ship_to_add_2, ord.ship_to_add_3, ord.ship_to_add_4, ord.ship_to_add_5,       
   ord.ship_to_city, ord.ship_to_state, ord.ship_to_zip, ord.ship_to_country, tempd.ShipToRegion, ord.cash_flag, ord.type, ord.back_ord_flag,       
   ord.freight_allow_pct, ord.route_code, ord.route_no, ord.date_printed, ord.date_transfered, ord.cr_invoice_no, ord.who_picked, ord.note,       
   ord.void, ord.void_who, ord.void_date, ord.changed, ord.remit_key, tempd.Forwarder, ord.freight_to, ord.sales_comm, ord.freight_allow_type,       
   ord.cust_dfpa, ord.location, ord.total_tax, ord.total_discount, ord.f_note, ord.invoice_edi, ord.edi_batch, ord.post_edi_date, 'N',       
   ord.gross_sales, ord.load_no, ord.curr_key, ord.curr_type, ord.curr_factor, ord.bill_to_key, ord.oper_factor, ord.tot_ord_tax, ord.tot_ord_disc,       
   ord.tot_ord_freight, ord.posting_code, ord.rate_type_home, ord.rate_type_oper, ord.reference_code, ord.hold_reason, tempd.DestZone,       
   ord.orig_no, ord.orig_ext, ord.tot_tax_incl, ord.process_ctrl_num, ord.batch_code, ord.tot_ord_incl, ord.barcode_status, ord.multiple_flag,       
   ord.so_priority_code, ord.FO_order_no, 0, ord.user_priority, ord.user_category, ord.from_date, ord.to_date, ord.consolidate_flag,      
   ord.proc_inv_no, ord.sold_to_addr1, ord.sold_to_addr2, ord.sold_to_addr3, ord.sold_to_addr4, ord.sold_to_addr5, ord.sold_to_addr6, '',      
   ord.ship_to_country_cd, ord.sold_to, ord.sold_to_country_cd, ord.sold_to_zip, ord.sold_to_state, ord.sold_to_city      
  from orders ord      
  inner join CVO_TempSO temp ON ord.order_no = temp.NewSO      
  inner join CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber      
  inner join adm_shipto_all adm (NOLOCK) ON adm.ship_to_code = temp.ShipTo      
  where ord.order_no = @order_no and ord.ext = 0      
  AND temp.ShipTo = tempd.ShipTo AND adm.customer_code = ord.cust_code      
      
      
      
      
  insert ord_list (      
          order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price, price_type,      
   note,status,cost,who_entered,sales_comm,temp_price,temp_type,cr_ordered, cr_shipped, discount, uom,      
   conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed, lb_tracking, labor, direct_dolrs, ovhd_dolrs,      
   util_dolrs,taxable,weight_ea,qc_flag,reason_code, qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,      
   total_tax,tax_code, curr_price, oper_price, display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs, reference_code,contract,agreement_id,      
   ship_to,service_agreement_flag,inv_available_flag, create_po_flag,load_group_no,return_code,user_count      
  )select distinct      
          ord.order_no, ordh.ext, ord.line_no, ord.location, ord.part_no, ord.description,convert(varchar(20),GETDATE(), 101) , ord.ordered, ord.shipped, ord.price, ord.price_type,       
   ord.note, 'N', ord.cost, ord.who_entered, ord.sales_comm, ord.temp_price, ord.temp_type, ord.cr_ordered, ord.cr_shipped, ord.discount, ord.uom,       
   ord.conv_factor, ord.void, ord.void_who, ord.void_date, ord.std_cost, ord.cubic_feet, ord.printed, ord.lb_tracking, ord.labor, ord.direct_dolrs,       
   ord.ovhd_dolrs, ord.util_dolrs, ord.taxable, ord.weight_ea, ord.qc_flag, ord.reason_code, ord.qc_no, ord.rejected, ord.part_type, ord.orig_part_no, ord.back_ord_flag, ord.gl_rev_acct,      
   ord.total_tax,ord.tax_code, ord.curr_price, ord.oper_price, ord.display_line, ord.std_direct_dolrs, ord.std_ovhd_dolrs,ord.std_util_dolrs, ord.reference_code, ord.contract, ord.agreement_id,      
   ord.ship_to, ord.service_agreement_flag, ord.inv_available_flag, ord.create_po_flag, ord.load_group_no, ord.return_code, ord.user_count      
  from ord_list ord (nolock)      
   inner join orders ordh (nolock) ON ord.order_no = ordh.order_no        
   inner join CVO_TempSO temp ON ordh.order_no = temp.NewSO      
   inner join CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber      
--   inner join adm_shipto_all adm (NOLOCK) ON adm.ship_to_code = tempd.ShipTo      
  where ordh.order_no = @order_no and ordh.ext > 0      
  AND ordh.ship_to = tempd.ShipTo AND ord.line_no = tempd.LineNumber      
      
      
        
  update orders      
  set status = 'N'      
  where order_no = @order_no      
  and ext = 0 and status <> 'C'      
      
      
  update ord_list      
  set status = 'N'      
  where order_no = @order_no      
  and order_ext = 0 and status <> 'C'      
      
      
/**/ 
GO
GRANT EXECUTE ON  [dbo].[adm_ins_SO_mutiship] TO [public]
GO
