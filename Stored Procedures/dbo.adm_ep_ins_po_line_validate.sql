SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
        
        
CREATE procedure [dbo].[adm_ep_ins_po_line_validate]        
@proc_po_no  varchar(20), --     REQUIRED        
@part_no  varchar(30), --     REQUIRED        
@location  varchar(10), --     REQUIRED        
@unit_measure varchar(2), --     REQUIRED (must have valid conversion to stocking UOM)        
@qty_ordered decimal(20,8), --    REQUIRED        
@type   char(1) = 'P', --    default to 'P' (can be M for misc part) if P, part will be         
      --       validated against inventory and set to M if not in         
      --       inventory)        
@vend_sku  varchar(30) = '', --   default ''        
@account_no  varchar(32) = '', --   default '' (will be set to inventory acct for inventory parts         
          --    in all cases)        
@description varchar(255) = '', --   default inv_master.description        
@curr_cost  decimal(20,8) = 0, --   default 0         
@note   varchar(255) = NULL, --   default NULL        
@who_entered varchar(20) = NULL, --    default user_name()        
@line   integer = 0, --     default 0 (if 0 will be set to max line for po        
@tax_code  varchar(10) = NULL, --   default purchase.tax_code        
@reference_code varchar(32) = '', --   default ''        
@project1  varchar(75) = '', --   default ''        
@project2  varchar(75) = '', --   default ''        
@project3  varchar(75) = '', --   default ''        
@tolerance_code varchar(10) = NULL, --   default NULL        
@shipto_code varchar(10) = NULL, --   default location        
@receiving_loc varchar(10) = NULL, --   default location        
@shipto_name varchar(40) = '', --   default '' (if '', set the address columns to the purchase         
          --    shipto address)        
@addr1   varchar(40) = '', --   default ''         
@addr2   varchar(40) = '', --   default ''        
@addr3   varchar(40) = '', --   default ''        
@addr4   varchar(40) = '', --   default ''        
@addr5   varchar(40) = '', --   default ''        
@city   varchar(40) = '', --   default ''        
@state   varchar(40) = '', --   default ''        
@zip   varchar(15) = '', --   default ''        
@country_cd  varchar(3) = '',  --   default ''        
@release_date datetime  = NULL,  --   default NULL if this value is set, a single release on the        
       -- releases table will be created for the qty_ordered         
       -- and a separate call to adm_ep_ins_po_rel will not be needed        
@error_description VARCHAR(8000) OUTPUT        
as        
        
declare @po_no varchar(16), @posting_code varchar(8),        
  @new_line int, @po_key int,        
  @curr_factor decimal(20,8), @oper_factor decimal(20,8),        
  @unit_cost decimal(20,8), @conv_factor decimal(20,8),        
  @lb_tracking char(1), @taxable int, @weight_ea decimal(20,8),        
  @oper_cost decimal(20,8), @rc int, @status char(1),        
  @i_uom char(2),        
  @vendor_cd varchar(12), @chk_sku_ind int        
        
if isnull(@proc_po_no,'') = ''          
BEGIN        
 SET @error_description = @error_description + '<ErrorCode>Detail Error Code -10</ErrorCode>'        
 SET @error_description = @error_description + '<ErrorInfo>The procurement po number can not be empty</ErrorInfo>'        
        
 GOTO EndProcedure        
END        
        
select @po_no = po_no,        
@po_key = po_key,        
@tax_code = isnull(@tax_code,tax_code),        
@addr1 = case when isnull(@shipto_name,'') = '' then ship_address1 else @addr1 end,        
@addr2 = case when isnull(@shipto_name,'') = '' then ship_address2 else @addr2 end,        
@addr3 = case when isnull(@shipto_name,'') = '' then ship_address3 else @addr3 end,        
@addr4 = case when isnull(@shipto_name,'') = '' then ship_address4 else @addr4 end,        
@addr5 = case when isnull(@shipto_name,'') = '' then ship_address5 else @addr5 end,        
@city = case when isnull(@shipto_name,'') = '' then ship_city else @city end,        
@state = case when isnull(@shipto_name,'') = '' then ship_state else @state end,        
@zip = case when isnull(@shipto_name,'') = '' then ship_zip else @zip end,        
@country_cd = case when isnull(@shipto_name,'') = '' then ship_country_cd else @country_cd end,        
@shipto_name = case when isnull(@shipto_name,'') = '' then ship_name else @shipto_name end,        
@curr_factor = curr_factor,        
@oper_factor = oper_factor,        
@status = status,        
@vendor_cd = vendor_no        
from purchase_all (nolock)         
where proc_po_no = @proc_po_no and status in ( 'O','H')        
        
if @po_no is NULL  return -11        
        
IF isnull(@part_no,'') = '' OR isnull(@location,'') = '' OR isnull(@unit_measure,'') = '' OR isnull(@qty_ordered,'') = 0           
BEGIN        
 if isnull(@part_no,'') = ''        
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -20</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>The part number can not be empty</ErrorInfo>'        
 END        
        
 if isnull(@location,'') = ''        
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -30</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>The location can not be empty</ErrorInfo>'        
 END        
        
 if isnull(@unit_measure,'') = ''         
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -40</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>The unite measure can not be empty</ErrorInfo>'        
 END        
        
 if isnull(@qty_ordered,'') = 0           
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -50</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>The quantity ordered can not be empty</ErrorInfo>'        
 END        
        
 GOTO EndProcedure        
END        
        
if @type not in ('P','M')          
BEGIN        
 SET @error_description = @error_description + '<ErrorCode>Detail Error Code -60</ErrorCode>'        
 SET @error_description = @error_description + '<ErrorInfo>The type can not be different from P or M</ErrorInfo>'        
        
 GOTO EndProcedure        
END        
        
if isnull(@receiving_loc,'') = ''  select @receiving_loc = @location        
if isnull(@shipto_code,'') = '' select @shipto_code = @location        
        
        
--if @type = 'P'  --fzambada test1        
--begin        
--  set @chk_sku_ind = 0        
--  while 1=1        
--  begin        
--    select @description = description,        
--      @posting_code = acct_code,        
--      @lb_tracking = lb_tracking,        
--      @taxable = taxable,        
--      @weight_ea = weight_ea,        
--      @i_uom = uom        
--    from inventory_unsecured_vw (nolock)        
--    where part_no = @part_no and location = @receiving_loc and void = 'N'        
--        
--    if @@rowcount > 0 break        
--    if @chk_sku_ind > 0         
-- BEGIN        
--  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -31</ErrorCode>'        
--  SET @error_description = @error_description + '<ErrorInfo>The chk sku ind can not be empty</ErrorInfo>'        
--        
--  GOTO EndProcedure        
-- END        
--        
--    set @chk_sku_ind = 1        
--       
----    select @part_no = sku_no,        
----      @vend_sku = vend_sku        
----    from vendor_sku (nolock)        
----    where vend_sku = @part_no and vendor_no = @vendor_cd        
--        
--    if @@rowcount = 0         
-- BEGIN        
--  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -31</ErrorCode>'        
--  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the part number and vendor code specified in the vendor table</ErrorInfo>'        
--        
--  GOTO EndProcedure        
-- END        
--        
--   end        
--        
--  set @conv_factor = 1        
--  if @i_uom != @unit_measure        
--  begin        
--    select @conv_factor = conv_factor        
--    from uom_table (nolock) where item = @part_no and         
--      std_uom = @i_uom and alt_uom = @unit_measure        
--           
--    if @@rowcount = 0        
--    begin        
--      select @conv_factor = conv_factor        
--      from uom_table (nolock) where item = 'STD' and         
--        std_uom = @i_uom and alt_uom = @unit_measure        
--        
--      if @@rowcount = 0        
--  BEGIN        
--   SET @error_description = @error_description + '<ErrorCode>Detail Error Code -41</ErrorCode>'        
--   SET @error_description = @error_description + '<ErrorInfo>There is not information related with the std uom and alt uom code specified in the uom table</ErrorInfo>'        
--        
--   GOTO EndProcedure        
--  END        
--    end        
--  end        
--        
--  select @account_no = inv_acct_code        
--  from in_account (nolock)        
--  where acct_code = @posting_code        
--        
--  if @@rowcount = 0          
-- BEGIN        
--  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -45</ErrorCode>'        
--  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the account code specified in the accounts table</ErrorInfo>'        
--        
--  GOTO EndProcedure        
-- END        
--end        
--else        
begin        
  if not exists (select 1 from uom_list (nolock)        
    where uom = @unit_measure and void = 'N')         
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -42</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the uom specified in the uom list</ErrorInfo>'        
        
  GOTO EndProcedure        
 END        
        
  if not exists (select 1 from locations_all (nolock)        
    where location = @receiving_loc)          
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -32</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the receiving location specified in the locations table</ErrorInfo>'        
        
  GOTO EndProcedure        
 END        
        
  if isnull(@description,'') = ''         
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -33</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>The description field can not be empty</ErrorInfo>'        
        
  GOTO EndProcedure        
 END        
        
  if isnull(@account_no,'') = ''        
    select @account_no = a.inv_acct_code        
    from in_account a (nolock)        
    join locations_all l on l.apacct_code = a.acct_code and l.location = @location        
        
  if not exists (select 1 from adm_glchart (nolock) where account_code = @account_no)        
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -34</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the account specified in the accounts table</ErrorInfo>'        
        
  GOTO EndProcedure        
 END        
            
  set @conv_factor = 1        
  set @lb_tracking = 'N'        
  set @taxable = 1        
  set @weight_ea = 0        
        
end        
        
set @weight_ea = round(@weight_ea * @conv_factor,4)        
        
if @location <> @receiving_loc        
begin        
  if not exists (select 1 from locations_all (nolock)        
    where location = @location)          
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -32</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the location specified in the location table</ErrorInfo>'        
        
  GOTO EndProcedure        
 END        
end        
if @location <> @shipto_code        
begin        
  if not exists (select 1 from locations_all (nolock)        
    where location = @shipto_code)          
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -33</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>There is not information related with the ship to specified in the location table</ErrorInfo>'        
        
  GOTO EndProcedure        
 END        
end        
        
set @new_line = 0        
if isnull(@line,0) = 0        
begin        
  if exists (select 1 from pur_list (nolock) where po_no = @po_no        
    and part_no = @part_no and receiving_loc = @receiving_loc and type = @type)        
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code 100</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>Can not duplicate lines into a purchase order</ErrorInfo>'        
        
  GOTO EndProcedure        
 END            
        
  set @new_line = 1        
  select @line = isnull((select max(line) from        
    pur_list (nolock) where po_no = @po_no),0) + 1        
end         
else if exists (select 1 from pur_list (nolock) where po_no = @po_no and line = @line        
  and not (part_no = @part_no and location = @location))        
 BEGIN        
  SET @error_description = @error_description + '<ErrorCode>Detail Error Code -70</ErrorCode>'        
  SET @error_description = @error_description + '<ErrorInfo>Can not duplicate lines into a purchase order</ErrorInfo>'        
        
  GOTO EndProcedure        
 END            
        
if @curr_cost is null select  @curr_cost = 0        
if @who_entered is NULL  select @who_entered = suser_name()        
         
EndProcedure: 
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_po_line_validate] TO [public]
GO
