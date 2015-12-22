SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE procedure [dbo].[adm_ep_ins_po_validate]    
@proc_po_no  varchar(20), --  REQUIRED    
@vendor_no  varchar(12), --  REQUIRED (apmaster_all.vendor_code)    
@ship_to_no  varchar(10), --  REQUIRED (locations.location)    
@curr_key  varchar(10), --  REQUIRED    
@date_of_order  datetime = NULL, --  default of getdate()    
@date_order_due  datetime = NULL, --  default of getdate()    
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
@note   varchar(255) = NULL, --  default of NULL    
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
@user_def_fld12  integer = 0, --   default 0    
@error_description VARCHAR(8000) OUTPUT    
as    
    
SET @error_description = ''    
    
declare @po_no varchar(16), @rc int    
declare @po_vendor varchar(12), @po_key int    
declare @rate_type_home varchar(8), @rate_type_oper varchar(8)    
declare @po_mask varchar(16)    
declare @oper_cur_code varchar(8), @home_cur_code varchar(8)    
declare @op_rate decimal(20,8), @nat_rate decimal(20,8),    
  @curr_date int, @retval int, @divop int    
    
select @po_no = '', @rc = 1    
    
IF isnull(@proc_po_no,'') = ''  OR isnull(@vendor_no,'') = ''      
BEGIN    
 if isnull(@proc_po_no,'') = ''      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -10</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The procurement po number can not be empty</ErrorInfo>'    
 END    
    
 if isnull(@vendor_no,'') = ''      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -20</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The vendor code can not be empty</ErrorInfo>'    
 END    
    
 GOTO EndProcedure    
END    
    
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
    
if @@rowcount = 0    
BEGIN    
 SET @error_description = @error_description + '<ErrorCode>Header Error Code -21</ErrorCode>'    
 SET @error_description = @error_description + '<ErrorInfo>There is no information related with the vendor code specified in the vendor table</ErrorInfo>'    
  drop table cvo_temppo  --fzambada
 GOTO EndProcedure    
END    
    
if isnull(@ship_to_no,'') = ''      
BEGIN    
 SET @error_description = @error_description + '<ErrorCode>Header Error Code -30</ErrorCode>'    
 SET @error_description = @error_description + '<ErrorInfo>The ship to can not be empty</ErrorInfo>'    
    
 GOTO EndProcedure    
END    
    
if not exists (select 1 from locations_all (nolock)    
  where location = @ship_to_no)     
BEGIN    
 SET @error_description = @error_description + '<ErrorCode>Header Error Code 31</ErrorCode>'    
 SET @error_description = @error_description + '<ErrorInfo>There is no information related with the ship to specified in the locations table</ErrorInfo>'    
    
 GOTO EndProcedure    
END    
    
if isnull(@curr_key,'') = ''      
BEGIN    
 SET @error_description = @error_description + '<ErrorCode>Header Error Code -40</ErrorCode>'    
 SET @error_description = @error_description + '<ErrorInfo>The currency key can not be empty</ErrorInfo>'    
    
 GOTO EndProcedure    
END    
    
if not exists (select 1 from glcurr_vw    
  where currency_code = @curr_key)     
BEGIN    
 SET @error_description = @error_description + '<ErrorCode>Header Error Code -41</ErrorCode>'    
 SET @error_description = @error_description + '<ErrorInfo>There is not information related with the currency key specified in the currency table</ErrorInfo>'    
    
 GOTO EndProcedure    
END    
    
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
    
IF isnull(@ship_via,'') = ''  OR isnull(@fob,'') = ''  OR isnull(@terms,'') = ''  OR    
 isnull(@tax_code,'') = ''  OR isnull(@posting_code,'') = ''  OR isnull(@rate_type_home,'') = '' OR    
 isnull(@rate_type_oper,'') = ''     
BEGIN    
 if isnull(@ship_via,'') = ''    
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -50</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The ship via field can not be empty</ErrorInfo>'     
 END    
    
 if isnull(@fob,'') = ''      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -51</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The fob field can not be empty</ErrorInfo>'     
 END    
    
 if isnull(@terms,'') = ''      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -52</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The terms field can not be empty</ErrorInfo>'     
 END    
    
 if isnull(@tax_code,'') = ''      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -53</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The tax code field can not be empty</ErrorInfo>'     
 END    
    
 if isnull(@posting_code,'') = ''      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -53</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The posting code field can not be empty</ErrorInfo>'     
 END    
    
 if isnull(@rate_type_home,'') = ''     
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -54</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The rate type home field can not be empty</ErrorInfo>'     
 END    
    
 if isnull(@rate_type_oper,'') = ''     
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -55</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The rate type operational field can not be empty</ErrorInfo>'     
 END    
    
 GOTO EndProcedure    
END    
    
if @location is not null    
begin    
  if not exists (select 1 from locations_all (nolock)    
  where location = @location)      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -60</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the location specified in the locations table</ErrorInfo>'     
    
  GOTO EndProcedure    
 END    
end    
else    
  set @location = @ship_to_no    
    
if @eprocurement_last_recv_date is null    
  select @eprocurement_last_recv_date = getdate()    
    
select @oper_cur_code = oper_currency,    
  @home_cur_code = home_currency    
from glco (nolock)    
    
    
IF isnull(@oper_cur_code,'') = ''  OR isnull(@home_cur_code,'') = ''     
BEGIN    
 if isnull(@oper_cur_code,'') = ''     
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -71</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The operational currency code can not be empty</ErrorInfo>'    
 END    
     
 if isnull(@home_cur_code,'') = ''    
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -71</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>The home currency code can not be empty</ErrorInfo>'    
 END    
    
 GOTO EndProcedure    
END    
    
    
select @po_no = po_no,    
@po_vendor = vendor_no    
from purchase_all (nolock)     
where proc_po_no = @proc_po_no    
    
if isnull(@po_no,'') != ''    
begin    
  if @po_vendor != @vendor_no      
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code -100</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>Can insert duplicate purchase order</ErrorInfo>'    
    
  GOTO EndProcedure    
 END    
  ELSE    
 BEGIN    
  SET @error_description = @error_description + '<ErrorCode>Header Error Code 100</ErrorCode>'    
  SET @error_description = @error_description + '<ErrorInfo>Can insert duplicate purchase order</ErrorInfo>'    
    
  GOTO EndProcedure    
 END      
end    
    
EndProcedure:    
  
  
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_po_validate] TO [public]
GO
