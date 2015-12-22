SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[scm_pb_set_dw_arcust1_sp]
@typ char(1), @timestamp varchar(20), @customer_key varchar(8)
, @customer_name varchar(40), @customer_short_name varchar(10)
, @addr1 varchar(40), @addr2 varchar(40), @addr3 varchar(40), @addr4 varchar(40)
, @addr5 varchar(40), @addr6 varchar(40), @addr_sort1 varchar(40)
, @addr_sort2 varchar(40), @addr_sort3 varchar(40), @status_type integer
, @attention_name varchar(40), @attention_phone varchar(30)
, @contact_name varchar(40), @contact_phone varchar(30), @tlx_twx varchar(30)
, @phone_1 varchar(30), @phone_2 varchar(30), @ship_to_code varchar(8)
, @tax_code varchar(8), @terms_code varchar(8), @fob_code varchar(8)
, @freight_code varchar(8), @posting_code varchar(8), @location_code varchar(8)
, @alt_location_code varchar(8), @dest_zone_code varchar(8)
, @territory_code varchar(8), @salesperson_code varchar(8)
, @fin_chg_code varchar(8), @price_code varchar(8), @payment_code varchar(8)
, @vendor_code varchar(12), @affiliated_cust_code varchar(8)
, @print_stmt_flag integer, @stmt_cycle_code varchar(8)
, @inv_comment_code varchar(8), @stmt_comment_code varchar(8)
, @dunn_message_code varchar(8), @note varchar(255), @discount float
, @invoice_copies integer, @iv_substitution integer, @ship_to_history integer
, @check_credit_limit integer, @credit_limit float, @check_aging_limit integer
, @aging_limit_bracket integer, @bal_fwd_flag integer
, @ship_complete_flag integer, @resale_num varchar(30), @db_num varchar(20)
, @db_date integer, @db_credit_rating varchar(20), @address_type integer
, @late_chg_type integer, @valid_payer_flag integer, @valid_soldto_flag integer
, @valid_shipto_flag integer, @payer_soldto_rel_code varchar(8)
, @across_na_flag integer, @date_opened integer, @rate_type_home varchar(8)
, @rate_type_oper varchar(8), @limit_by_home integer, @nat_cur_code varchar(8)
, @one_cur_cust integer, @added_by_user_name varchar(30)
, @added_by_date datetime, @modified_by_user_name varchar(30)
, @modified_by_date datetime, @url varchar(255), @si varchar(255)
, @price_level char(1), @remit_code varchar(10), @forwarder_code varchar(10)
, @freight_to_code varchar(10), @route_code varchar(10), @route_no integer
, @city varchar(40), @state varchar(40), @postal_code varchar(15)
, @country varchar(40), @routing varchar(8), @c_country_code varchar(3)
, @tax_id_num varchar(17), @consolidated_invoices integer
, @writeoff_code varchar(8), @delivery_days integer
, @crelated_org_name varchar(255), @corganization_name varchar(255)
, @extended_name varchar(120), @check_extendedname_flag int
 AS
BEGIN
set nocount on
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
rollback tran 
raiserror 99001 'You cannot create a new customer from SCM'
return
end
if @typ = 'U'
begin
update armaster_all set
address_name = @customer_name
, short_name= @customer_short_name
, addr1= @addr1, addr2= @addr2
, addr3= @addr3, addr4= @addr4
, addr5= @addr5, addr6= @addr6
, addr_sort1= @addr_sort1, addr_sort2= @addr_sort2
, addr_sort3= @addr_sort3, status_type= @status_type
, attention_name= @attention_name
, attention_phone= @attention_phone
, contact_name= @contact_name
, contact_phone= @contact_phone, tlx_twx= @tlx_twx
, phone_1= @phone_1, phone_2= @phone_2
, ship_to_code= @ship_to_code, tax_code= @tax_code
, terms_code= @terms_code, fob_code= @fob_code
, freight_code= @freight_code
, posting_code= @posting_code
, location_code= @location_code
, alt_location_code= @alt_location_code
, dest_zone_code= @dest_zone_code
, territory_code= @territory_code
, salesperson_code= @salesperson_code
, fin_chg_code= @fin_chg_code, price_code= @price_code
, payment_code= @payment_code
, vendor_code= @vendor_code
, affiliated_cust_code= @affiliated_cust_code
, print_stmt_flag= @print_stmt_flag
, stmt_cycle_code= @stmt_cycle_code
, inv_comment_code= @inv_comment_code
, stmt_comment_code= @stmt_comment_code
, dunn_message_code= @dunn_message_code, note= @note
, trade_disc_percent= @discount
, invoice_copies= @invoice_copies
, iv_substitution= @iv_substitution
, ship_to_history= @ship_to_history
, check_credit_limit= @check_credit_limit
, credit_limit= @credit_limit
, check_aging_limit= @check_aging_limit
, aging_limit_bracket= @aging_limit_bracket
, bal_fwd_flag= @bal_fwd_flag
, ship_complete_flag= @ship_complete_flag
, resale_num= @resale_num, db_num= @db_num
, db_date= @db_date
, db_credit_rating= @db_credit_rating
, address_type= @address_type
, late_chg_type= @late_chg_type
, valid_payer_flag= @valid_payer_flag
, valid_soldto_flag= @valid_soldto_flag
, valid_shipto_flag= @valid_shipto_flag
, payer_soldto_rel_code= @payer_soldto_rel_code
, across_na_flag= @across_na_flag
, date_opened= @date_opened
, rate_type_home= @rate_type_home
, rate_type_oper= @rate_type_oper
, limit_by_home= @limit_by_home
, nat_cur_code= @nat_cur_code
, one_cur_cust= @one_cur_cust
, added_by_user_name= @added_by_user_name
, added_by_date= @added_by_date
, modified_by_user_name= @modified_by_user_name
, modified_by_date= @modified_by_date, url= @url
, special_instr= @si, price_level= @price_level
, remit_code= @remit_code
, forwarder_code= @forwarder_code
, freight_to_code= @freight_to_code
, route_code= @route_code, route_no= @route_no
, city= @city, state= @state
, postal_code= @postal_code, country= @country
, ship_via_code= @routing
, country_code= @c_country_code
, tax_id_num= @tax_id_num
, consolidated_invoices= @consolidated_invoices
, writeoff_code= @writeoff_code
, delivery_days= @delivery_days
, extended_name = @extended_name
, check_extendedname_flag = isnull(@check_extendedname_flag,0)
where customer_code= @customer_key
 and timestamp = @ts
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end

end
if @typ = 'D'
begin
rollback tran 
raiserror 99001 'You cannot delete a customer from SCM'
return
end

return
end



GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_arcust1_sp] TO [public]
GO
