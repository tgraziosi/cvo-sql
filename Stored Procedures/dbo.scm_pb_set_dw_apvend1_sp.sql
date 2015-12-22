SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[scm_pb_set_dw_apvend1_sp]
@typ char(1), @timestamp varchar(20), @vendor_key varchar(12)
, @vendor_name varchar(40), @vendor_short_name varchar(10), @addr1 varchar(40)
, @addr2 varchar(40), @addr3 varchar(40), @addr4 varchar(40), @addr5 varchar(40)
, @addr6 varchar(40), @addr_sort1 varchar(40), @addr_sort2 varchar(40)
, @addr_sort3 varchar(40), @c_status_type integer, @attention_name varchar(40)
, @attention_phone varchar(30), @contact_name varchar(40)
, @contact_phone varchar(30), @tlx_twx varchar(30), @phone_1 varchar(30)
, @phone_2 varchar(30), @pay_to_code varchar(8), @tax_code varchar(8)
, @terms varchar(8), @fob varchar(8), @posting_code varchar(8)
, @location_code varchar(8), @orig_zone_code varchar(8)
, @customer_code varchar(8), @affiliated_vend_code varchar(12)
, @alt_vendor_code varchar(12), @comment_code varchar(8)
, @vend_class_code varchar(8), @branch_code varchar(8)
, @pay_to_hist_flag integer, @item_hist_flag integer, @credit_limit_flag integer
, @credit_limit float, @aging_limit_flag integer, @aging_limit integer
, @restock_chg_flag integer, @restock_chg float, @prc_flag integer
, @vend_acct varchar(20), @tax_id_num varchar(20), @flag_1099 integer
, @exp_acct_code varchar(32), @amt_max_check float, @lead_time integer
, @one_check_flag integer, @dup_voucher_flag integer, @dup_amt_flag integer
, @code_1099 varchar(8), @user_trx_type_code varchar(8)
, @payment_code varchar(8), @address_type integer, @limit_by_home integer
, @rate_type_home varchar(8), @rate_type_oper varchar(8)
, @nat_cur_code varchar(8), @one_cur_vendor integer, @cash_acct_code varchar(32)
, @state varchar(40), @zip_code varchar(15), @country varchar(40)
, @freight_code varchar(10), @note varchar(255), @country_code varchar(3)
, @etransmit_ind integer, @buying_cycle integer, @proc_vend_flag integer
, @related_org_name varchar(255), @org_name varchar(255)
, @extended_name varchar(120), @check_extendedname_flag int
 AS
BEGIN
set nocount on
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output

if @typ = 'I'
begin
rollback tran 
raiserror 99001 'You cannot create a new vendor from SCM'
return
end
if @typ = 'U'
begin
update apmaster_all 
set address_name = @vendor_name
, short_name= @vendor_short_name, addr1= @addr1
, addr2= @addr2, addr3= @addr3
, addr4= @addr4, addr5= @addr5
, addr6= @addr6, attention_name= @attention_name
, attention_phone= @attention_phone
, contact_name= @contact_name
, contact_phone= @contact_phone, phone_1= @phone_1
, phone_2= @phone_2, fob_code= @fob
, location_code= @location_code
, orig_zone_code= @orig_zone_code
, customer_code= @customer_code
, affiliated_vend_code= @affiliated_vend_code
, alt_vendor_code= @alt_vendor_code
, vend_class_code= @vend_class_code
, branch_code= @branch_code
, etransmit_ind= @etransmit_ind
, buying_cycle= @buying_cycle
, proc_vend_flag= @proc_vend_flag
, extended_name = @extended_name
, check_extendedname_flag = isnull(@check_extendedname_flag,0)
where vendor_code = @vendor_key and timestamp = @ts
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
raiserror 99001 'You cannot delete a vendor from SCM'
return
end
end

GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_apvend1_sp] TO [public]
GO
