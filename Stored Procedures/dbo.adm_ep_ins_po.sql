SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
                        
                        
                        
                        
                        
                        
                        
                        
                                                                        
                        
                        
                        
CREATE procedure [dbo].[adm_ep_ins_po]                        
@proc_po_no  varchar(20), --  REQUIRED                        
@vendor_no  varchar(12), --  REQUIRED (apmaster_all.vendor_code)                        
@ship_to_no  varchar(10), --  REQUIRED (locations.location)                        
@curr_key  varchar(10), --  REQUIRED                        
@date_of_order  datetime, -- = NULL, --  default of getdate()                        
@date_order_due  datetime, --= NULL, --  default of getdate()                        
@ship_name  varchar(40) = '', --  default of '' (if ship addresses entries all blank, will                         
@ship_address1  varchar(40) = '', --  default of '' use address from locations table)                        
@ship_address2  varchar(40) = '', --  default of ''                        
@ship_address3  varchar(40) = '', --  default of ''                        
@ship_address4  varchar(40) = '', --  default of ''                        
@ship_address5  varchar(40) = '', --  default of ''                        
@ship_city  varchar(40) = '', --  default of ''                        
@ship_state  varchar(40) = '', --  default of ''                        
@ship_country_cd  varchar(3) = '', --  default of ''                        
@ship_zip  varchar(15) = '*', --  default of ''                        
@ship_via  varchar(10) = '*', --  default apmaster_all.freight_code                        
@fob   varchar(10) = '*', --  default apmaster_all.fob_code                        
@tax_code  varchar(10) = '*', --  default apmaster_all.tax_code                        
@terms   varchar(10) = '*', --  default apmaster_all.terms_code                        
@attn   varchar(30) = '*', --  default apmaster_all.attention_name                        
@who_entered  varchar(20) = NULL, --  default user_name()                        
@email_name  varchar(20) = '*', --  default apmaster_all.attention_email                        
@note   varchar(255),-- = NULL, --  default of NULL                        
@buyer   varchar(10) = NULL, --  default of NULL                        
@location  varchar(10) = NULL, --  default of Ship_to_no                        
@phone   varchar(30) = '*', --  default apmaster_all.attention_phone                        
@posting_code  varchar(8) = '*', --  default apmaster_all.posting_code                        
@expedite_flag  smallint = 0, --  default 0                        
@vend_order_no  varchar(16) = NULL, --   default NULL                        
@requested_by  varchar(40) = NULL, --  default NULL                        
@approved_by  varchar(40) = NULL, --  default NULL                        
@user_category  varchar(8) = '', --  default ''                        
@etransmit_status char(1) = NULL, --   default NULL                        
@approval_status  char(1) = NULL, --   default NULL                        
@etransmit_date  datetime = NULL, --  default NULL                        
@eprocurement_last_sent_date datetime = NULL, -- default NULL                        
@eprocurement_last_recv_date datetime = NULL, -- default getdate()                        
@user_def_fld1  varchar(255)  = '', --  default ''                        
@user_def_fld2  varchar(255)  = '', --  default ''                        
@user_def_fld3  varchar(255)  = '', --  default ''                        
@user_def_fld4  varchar(255)  = '', --  default ''                        
@user_def_fld5  float = 0, --   default 0                        
@user_def_fld6  float = 0, --   default 0                        
@user_def_fld7  float = 0, --   default 0                        
@user_def_fld8  float = 0, --   default 0               
@user_def_fld9  integer = 0, --   default 0                        
@user_def_fld10  integer = 0, --   default 0                        
@user_def_fld11  integer = 0, --   default 0                        
@user_def_fld12  integer = 0 --   default 0                        
as                        
set nocount on                        
                        
declare @po_no varchar(16), @rc int                        
declare @po_vendor varchar(12), @po_key int                        
declare @rate_type_home varchar(8), @rate_type_oper varchar(8)                        
declare @po_mask varchar(16)                        
declare @oper_cur_code varchar(8), @home_cur_code varchar(8)                     
declare @op_rate decimal(20,8), @nat_rate decimal(20,8),                        
  @curr_date int, @retval int, @divop int                        
            select @po_no = '', @rc = 1                        
                        
if isnull(@proc_po_no,'') = ''  return -10                        
if isnull(@vendor_no,'') = ''  return -20                  
                        
select                         
@ship_via = case when isnull(@ship_via,'') = '*' then freight_code else @ship_via end,                        
@fob = case when isnull(@fob,'') = '*' then fob_code else @fob end,                        
@tax_code = case when isnull(@tax_code,'') = '*' then tax_code else @tax_code end,                        
@terms = case when isnull(@terms,'') = '*' then terms_code else @terms end,                        
@attn = case when isnull(@attn,'') = '*' then attention_name else @attn end,                        
@email_name = case when isnull(@email_name,'') = '*' then attention_email else @email_name end,                        
@phone = case when isnull(@phone,'') = '*' then attention_phone else @phone end,                        
@posting_code = case when isnull(@posting_code,'') = '*' then posting_code else @posting_code end,                        
@rate_type_home = rate_type_home,                        
@rate_type_oper = rate_type_oper                        
from adm_vend_all (nolock)                        
where vendor_code = @vendor_no                        
                        
if @@rowcount = 0 return -21                        
                        
if isnull(@ship_to_no,'') = ''  return -30                        
                        
if not exists (select 1 from locations_all (nolock)                        
  where location = @ship_to_no) return 31                        
                        
if isnull(@curr_key,'') = ''  return -40                        
                        
if not exists (select 1 from glcurr_vw                        
  where currency_code = @curr_key) return -41                        
                   
if @date_of_order is null  select @date_of_order = getdate()                        
if @date_order_due is null select @date_order_due = getdate()                        
if isnull(@ship_name,'') = '' and isnull(@ship_address1,'') = ''                         
begin                        
  select @ship_name = name,                        
    @ship_address1 = addr1,                        
    @ship_address2 = addr2,                         
    @ship_address3 = addr3,                        
    @ship_address4 = addr4,                        
    @ship_address5 = addr5,                        
    @ship_city = city,                        
    @ship_state = state,                        
    @ship_country_cd = country_code,                        
    @ship_zip = zip                        
  from locations_all (nolock)                        
  where location = @ship_to_no                        
end                        
                        
if @who_entered is NULL  select @who_entered = suser_name()                        
                        
if isnull(@ship_via,'') = ''  return -50                        
if isnull(@fob,'') = ''  return -51                        
if isnull(@terms,'') = ''  return -52                        
if isnull(@tax_code,'') = ''  return -53                        
if isnull(@posting_code,'') = ''  return -53                        
if isnull(@rate_type_home,'') = '' return -54                        
if isnull(@rate_type_oper,'') = '' return -55                        
                        
                        
if @location is not null                        
begin                        
  if not exists (select 1 from locations_all (nolock)                        
  where location = @location)  return -60                       
end                        
else                        
  set @location = @ship_to_no                        
                        
if @eprocurement_last_recv_date is null                        
  select @eprocurement_last_recv_date = getdate()                        
                        
select @oper_cur_code = oper_currency,                        
  @home_cur_code = home_currency                        
from glco (nolock)                        
                        
if isnull(@oper_cur_code,'') = '' return -71                        
if isnull(@home_cur_code,'') = '' return -71                        
                        
--select @po_no = po_no,                        
select @po_no = proc_po_no, --fzambada custom PO number                      
@po_vendor = vendor_no                        
from purchase_all (nolock)                         
where proc_po_no = @proc_po_no                        
                        
if isnull(@po_no,'') != ''                        
begin                        
  if @po_vendor != @vendor_no  return -100                        
                        
  return 100                        
end                        
else                        
begin                        
  select @curr_date = datediff(day,'01/01/1900',@date_order_due) + 693596                        
  exec @retval = adm_mccurate_sp  @curr_date, @curr_key, @home_cur_code,                        
    @rate_type_home, @nat_rate OUTPUT, 0, @divop OUTPUT                        
         
  if @retval <> 0  return -110                        
                        
  exec @retval = adm_mccurate_sp  @curr_date, @curr_key, @oper_cur_code,                        
    @rate_type_oper, @op_rate OUTPUT, 0, @divop OUTPUT                        
                        
  if @retval <> 0  return -111                        
                        
  begin tran                     
    update next_po_no                        
    set last_no = last_no + 1                        
                        
    select @po_key = last_no from next_po_no                        
    select @po_mask = value_str from config (nolock)                         
      where flag = 'PUR_PO_MASK'                        
                        
    exec fs_fmtctlnm_sp @po_key, @po_mask, @po_no OUT, @rc OUT, 1                        
                        
    if @rc < 0 or isnull(@po_no,'') = ''                        
    begin                         
      rollback tran                        
      return -201                        
    end                        
set @po_no=@proc_po_no --fzambada custom PO                    
set @note=SUBSTRING(@note,1,30)                
                        
  insert purchase_all (po_no,status,po_type,printed,vendor_no,date_of_order,                        
    date_order_due,ship_to_no,ship_name,ship_address1,ship_address2,                        
    ship_address3,ship_address4,ship_address5,ship_city,ship_state,                        
   ship_zip,ship_via,fob,tax_code,terms,attn,footing,blanket,                        
    who_entered,total_amt_order,freight,date_to_pay,discount,                        
    prepaid_amt,vend_inv_no,email,email_name,freight_flag,                        
    freight_vendor,freight_inv_no,void,void_who,void_date,note,                        
    po_key,po_ext,curr_key,curr_type,curr_factor,buyer,location,                        
    prod_no,oper_factor,hold_reason,phone,total_tax,rate_type_home,        rate_type_oper,reference_code,posting_code,user_code,expedite_flag,                        
    vend_order_no,requested_by,approved_by,user_category,blanket_flag,                        
    date_blnk_from,date_blnk_to,amt_blnk_limit,etransmit_status,                        
    approval_status,etransmit_date,eprocurement_last_sent_date,                        
  eprocurement_last_recv_date,user_def_fld1,user_def_fld2,                        
    user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,                        
    user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,                        
    user_def_fld11,user_def_fld12,one_time_vend_ind,vendor_addr1,                        
    vendor_addr2,vendor_addr3,vendor_addr4,vendor_addr5,vendor_addr6,                      
    ship_country_cd,vendor_city,vendor_state,vendor_zip,                        
    vendor_country_cd,tax_valid_ind,addr_valid_ind,                        
    vendor_addr_valid_ind,proc_po_no)                        
  select @po_no, 'O', 'XX', 'N', @vendor_no, @date_of_order, @date_order_due,                        
    @ship_to_no, @ship_name, @ship_address1, @ship_address2,                         
    @ship_address3, @ship_address4, @ship_address5, @ship_city,                        
    @ship_state, @ship_zip, @ship_via, @fob, @tax_code, @terms,                        
    @note, NULL, 'N', 'ELABARBERA', 0, 0, NULL, 0, 0, NULL,                        
    NULL, @email_name, NULL, NULL, NULL, 'N', NULL, NULL,                        
    @note, convert(int,@po_no), 0, @curr_key, NULL, @nat_rate, 'TRACI',                        
    @location, 0, @op_rate, NULL, @phone, 0, @rate_type_home,              
    @rate_type_oper, NULL, @posting_code, '', 0, @vend_order_no,                        
    @requested_by, @approved_by, @user_category, 0, NULL, NULL,                        
    NULL, @etransmit_status, @approval_status, @etransmit_date,                        
    @eprocurement_last_sent_date, NULL,                        
    @user_def_fld1, @user_def_fld2, @user_def_fld3, @user_def_fld4,                        
    @user_def_fld5, @user_def_fld6, @user_def_fld7, @user_def_fld8,                      
    @user_def_fld9, @user_def_fld10, @user_def_fld11,                        
    @user_def_fld12, 0, NULL, NULL, NULL, NULL, NULL, NULL,                        
    @ship_country_cd, NULL, NULL, NULL, NULL, 1, NULL, NULL, @proc_po_no                        
                        
  if @@error <> 0                        
  begin              
	select ERROR_MESSAGE()          
    rollback tran                        
    return -202                        
  end                        
                        
  commit tran                        
end                        
                        
if @po_no = ''                 
begin                        
  return -101                        
end                        
                        
return 1 
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_po] TO [public]
GO
