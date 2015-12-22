SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
                                    
                                    
                                    
CREATE procedure [dbo].[adm_ep_ins_po_line]                                    
@proc_po_no  varchar(20), --     REQUIRED                                    
@part_no  varchar(30), --     REQUIRED                                    
@location  varchar(10), --     REQUIRED                                    
@unit_measure varchar(2), --     REQUIRED (must have valid conversion to stocking UOM)                                    
@qty_ordered decimal(20,8), --    REQUIRED                                    
@type   char(1) = 'M', --    default to 'P' (can be M for misc part) if P, part will be                                     
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
@release_date datetime   --   default NULL if this value is set, a single release on the                                    
       -- releases table will be created for the qty_ordered                                     
       -- and a separate call to adm_ep_ins_po_rel will not be needed                                    
as                                    
set nocount on                                    
                                    
declare @po_no varchar(16), @posting_code varchar(8),                                    
  @new_line int, @po_key int,                                    
  @curr_factor decimal(20,8), @oper_factor decimal(20,8),                                    
  @unit_cost decimal(20,8), @conv_factor decimal(20,8),                          
  @lb_tracking char(1), @taxable int, @weight_ea decimal(20,8),                           
  @oper_cost decimal(20,8), @rc int, @status char(1),              
  @i_uom char(2),                                    
  @vendor_cd varchar(12), @chk_sku_ind int                                 
                                    
if isnull(@proc_po_no,'') = ''  return -10                           
                                    
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
                                    
if isnull(@part_no,'') = ''  return -20                                    
if isnull(@location,'') = '' return -30                                    
    if isnull(@unit_measure,'') = '' return -40                                    
        
               
        
if isnull(@qty_ordered,0) = 0   return -50                                    
                                    
if @type not in ('P','M')  return -60                                    
                                    
if isnull(@receiving_loc,'') = ''  select @receiving_loc = @location                                    
if isnull(@shipto_code,'') = '' select @shipto_code = @location                                    
                                    
                                  
                                    
if @type = 'P'                                    
begin                                    
  set @chk_sku_ind = 0                                    
  while 1=1                                    
  begin                                    
    select @description = description,                                    
      @posting_code = acct_code,                                    
      @lb_tracking = lb_tracking,                                    
      @taxable = taxable,                                    
      @weight_ea = weight_ea,                                    
      @i_uom = uom                                    
    from inventory_unsecured_vw (nolock)                                    
    where part_no = @part_no and location = @receiving_loc and void = 'N'                                    
                                    
   if @@rowcount > 0 break                                    
    if @chk_sku_ind > 0 return -31                                    
                                    
    set @chk_sku_ind = 1                  
                                    
    select @part_no = sku_no,                                    
      @vend_sku = vend_sku                                    
    from vendor_sku (nolock)                               
    where vend_sku = @part_no and vendor_no = @vendor_cd                                    
                                    
    if @@rowcount = 0 return -31                                    
   end                    
                                    
  set @conv_factor = 1                                    
  if @i_uom != @unit_measure                                    
  begin                                    
    select @conv_factor = conv_factor                                    
    from uom_table (nolock) where item = @part_no and                                     
      std_uom = @i_uom and alt_uom = @unit_measure                                    
                                       
    if @@rowcount = 0                                    
    begin                                    
      select @conv_factor = conv_factor                                    
      from uom_table (nolock) where item = 'STD' and                                     
        std_uom = @i_uom and alt_uom = @unit_measure                                    
                                    
      if @@rowcount = 0                                    
        return -41                                    
    end                                    
  end                                    
                                    
--  select @account_no = inv_acct_code                       
--  from in_account (nolock)                                    
--  where acct_code = @posting_code   --fzambada REv3      
      
 select @account_no = inv_acct_code       
 from in_account (nolock)      
 where acct_code = (select acct_code from inv_list where part_no = @part_no and location=@location)                                    
                                    
  if @@rowcount = 0  return -45                                    
end                                    
else                                    
begin                                    
  if not exists (select 1 from uom_list (nolock)                                    
    where uom = @unit_measure and void = 'N') return -42                                    
                                    
  if not exists (select 1 from locations_all (nolock)                                    
    where location = @receiving_loc)  return -32                                    
                    if isnull(@description,'') = ''                                     
    return -33                                    
                                    
  if isnull(@account_no,'') = ''                                    
    select @account_no = a.inv_acct_code                                    
    from in_account a (nolock)                                    
    join locations_all l on l.apacct_code = a.acct_code and l.location = @location                                    
                                  
  --if not exists (select 1 from adm_glchart_all (nolock) where account_code = @account_no)                                    
    --return -34 --fzambada                                    
                                    
  set @conv_factor = 1                                    
  set @lb_tracking = (select top(1) lb_tracking from inv_master where part_no=@part_no)--'N'   fzambada rev4                                 
--select * from inv_master  
  set @taxable = 1                                
  set @weight_ea = 0                                    
                                    
end                                    
                                    
set @weight_ea = round(@weight_ea * @conv_factor,4)                                    
                                    
if @location <> @receiving_loc                                    
begin                                    
  if not exists (select 1 from locations_all (nolock)                                    
    where location = @location)  return -32                                    
end                                    
if @location <> @shipto_code                                    
begin                                    
  if not exists (select 1 from locations_all (nolock)                                    
    where location = @shipto_code)  return -33                                    
end                                    
                                    
set @new_line = 0                     
if isnull(@line,0) = 0                                    
begin                                    
--  if exists (select 1 from pur_list (nolock) where po_no = @po_no                                    
--    and part_no = @part_no and receiving_loc = @receiving_loc and type = @type)                                    
-- GOTO Release;                              
    --return 100                              
                                    
                                    
  set @new_line = 1                                    
  select @line = isnull((select max(line) from                                    
    pur_list (nolock) where po_no = @po_no),0) + 1                                    
end                                     
else if exists (select 1 from pur_list (nolock) where po_no = @po_no and line = @line                                    
  and not (part_no = @part_no and location = @location))                                    
    return -70                                  
                                    
if @curr_cost is null select  @curr_cost = 0                                    
if @who_entered is NULL  select @who_entered = suser_name()                                    
                                     
if @new_line = 0                                    
begin                                    
    return 100                                    
end                                     
else                         
begin                                    
  select @unit_cost = case when @curr_factor < 0 then @curr_cost / abs(@curr_factor)                                    
    else @curr_cost * @curr_factor end                                    
                                    
  select @oper_cost = case when @oper_factor < 0 then @curr_cost / abs(@oper_factor)                                    
    else @curr_cost * @oper_factor end                                    
         /*                        
  SELECT                                      
    @release_date = CASE ISNULL(TEMP.RequiredDate,0) WHEN 0 THEN GETDATE()                                    
      ELSE (SELECT dateadd(day, TEMP.RequiredDate - 693596,'01/01/1900')) END                                    
  FROM CVO_TEMPPO TEMP */                         
set @description=(select top (1) description from inv_master where part_no=@part_no)    
    
IF @account_no=''    
BEGIN    
set @account_no='1400000000000'    
END                
    
                                   
--se tiene que poner un IF para ver si es un release y si si sumarle la cantidad original a la orden                               
  begin tran                                    
  insert pur_list (po_no,part_no,location,type,vend_sku,account_no,description,unit_cost,                                    
    unit_measure,note,rel_date,qty_ordered,qty_received,who_entered,status,ext_cost,                                    
    conv_factor,void,void_who,void_date,lb_tracking,line,taxable,prev_qty,po_key,weight_ea,                                    
    tax_code,curr_factor,oper_factor,total_tax,curr_cost,oper_cost,reference_code,                                    
    project1,project2,project3,tolerance_code,shipto_code,receiving_loc,shipto_name,                                    
    addr1,addr2,addr3,addr4,addr5,receipt_batch_no,city,state,zip,country_cd,addr_valid_ind)                
--,orig_part_type)                                    
  select @po_no,@part_no,@location,'M',@vend_sku,@account_no,@description,@unit_cost,                                    
    @unit_measure,@note,@release_date,0,0,@who_entered,@status,0,                                    
    @conv_factor,'N',null,null,@lb_tracking,@line,@taxable,0,@po_key,@weight_ea,                               
    @tax_code,@curr_factor,@oper_factor,0,@curr_cost,@oper_cost,@reference_code,                                    
    --@project1,@project2,@project3,@tolerance_code,@shipto_code,@receiving_loc,@shipto_name,                                    
@project1,@project2,@project3,'STD',@shipto_code,@receiving_loc,@shipto_name,                                    
    @addr1,@addr2,@addr3,@addr4,@addr5,0,@city,@state,@zip,@country_cd,NULL              
--,'P'                                  
                  
                              
                                    
                           
                              
                                    
  if @@error <> 0                                    
  begin                                    
    rollback tran                                     
    return -200                                    
  end                                    
                                    
  commit tran                                    
                              
                                    
  if @release_date is not NULL                                    
  begin                                    
RELEASE:                              
--set @line=(select distinct line from pur_list (nolock) where po_no = @po_no                                    
set @line=(select max(line) from pur_list (nolock) where po_no = @po_no                                    
    and part_no = @part_no and receiving_loc = @receiving_loc and type = @type)                              
--set @proc_po_no=@po_no                            
    exec @rc = adm_ep_ins_po_rel @proc_po_no, @line, @release_date, @qty_ordered                                    
                                     
    return @rc                                    
  end                                    
end                                     
                              
return 1 
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_po_line] TO [public]
GO
