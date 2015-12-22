SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[scm_pb_set_dw_inv_main_sp] 
@typ char(1), @part_no varchar(30), @upc_code varchar(20), @sku_no varchar(30)
, @description varchar(255), @vendor_key varchar(12), @category varchar(10)
, @c_type_code varchar(10), @status char(1), @cubic_feet decimal(20,8)
, @weight_ea decimal(20,8), @labor decimal(20,8), @uom varchar(2)
, @account varchar(32), @c_comm_type varchar(10), @void char(1)
, @void_who varchar(20), @void_date datetime, @entered_who varchar(20)
, @entered_date datetime, @std_cost decimal(20,8), @utility_cost decimal(20,8)
, @qc_flag char(1), @note varchar(255), @lb_tracking char(1), @uom2 varchar(2)
, @freight_unit decimal(20,8), @taxable integer, @c_freight_class varchar(10)
, @conv_factor decimal(20,8), @adm_vend_all_vendor_name varchar(40)
, @cycle_type varchar(10), @inv_cost_method char(1), @c_buyer varchar(10)
, @allow_fractions integer, @cfg_flag char(1), @tax_code varchar(10)
, @obsolete integer, @serial_flag integer, @c_ole_data decimal(20,8)
, @c_curr_key varchar(8), @web_saleable_flag char(1), @tolerance_cd varchar(10)
, @inv_master_reg_prod char(1), @inv_master_warranty_length integer
, @inv_master_call_limit integer, @pur_prod_flag char(1)
, @c_country_desc varchar(3), @cmdty_code varchar(8), @min_profit_perc integer
, @height decimal(20,8), @width decimal(20,8), @length decimal(20,8)
, @sku_code varchar(16), @c_min_profit_enabled integer
, @inv_master_eprocurement_flag integer, @inv_master_non_sellable_flag char(1)
, @add_comment char(1), @so_qty_increment decimal(20,8), @p_org_id varchar(30)
, @timestamp varchar(20)
 AS
BEGIN
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
Insert into inv_master (inv_master.part_no, inv_master.upc_code, inv_master.sku_no
, inv_master.description, inv_master.vendor, inv_master.category
, inv_master.type_code, inv_master.status, inv_master.cubic_feet
, inv_master.weight_ea, inv_master.labor, inv_master.uom, inv_master.account
, inv_master.comm_type, inv_master.void, inv_master.void_who
, inv_master.void_date, inv_master.entered_who, inv_master.entered_date
, inv_master.std_cost, inv_master.utility_cost, inv_master.qc_flag
, inv_master.note, inv_master.lb_tracking, inv_master.rpt_uom
, inv_master.freight_unit, inv_master.taxable, inv_master.freight_class
, inv_master.conv_factor, inv_master.cycle_type, inv_master.inv_cost_method
, inv_master.buyer, inv_master.allow_fractions, inv_master.cfg_flag
, inv_master.tax_code, inv_master.obsolete, inv_master.serial_flag
, inv_master.web_saleable_flag, inv_master.tolerance_cd, inv_master.reg_prod
, inv_master.warranty_length, inv_master.call_limit, inv_master.pur_prod_flag
, inv_master.country_code, inv_master.cmdty_code, inv_master.min_profit_perc
, inv_master.height, inv_master.width, inv_master.length, inv_master.sku_code
, inv_master.eprocurement_flag, inv_master.non_sellable_flag
, inv_master.so_qty_increment
)
values (@part_no, @upc_code, @sku_no, @description, @vendor_key, @category
, @c_type_code, isnull(@status,('A')), @cubic_feet, @weight_ea, @labor, @uom
, @account, @c_comm_type, isnull(@void,('N')), @void_who, @void_date
, @entered_who, @entered_date, isnull(@std_cost,(0)), isnull(@utility_cost,(0))
, isnull(@qc_flag,('N')), @note, isnull(@lb_tracking,('N')), @uom2
, @freight_unit, isnull(@taxable,(0)), @c_freight_class
, isnull(@conv_factor,(1)), @cycle_type, isnull(@inv_cost_method,('A'))
, @c_buyer, isnull(@allow_fractions,(1)), isnull(@cfg_flag,('N')), @tax_code
, isnull(@obsolete,(0)), isnull(@serial_flag,(0))
, isnull(@web_saleable_flag,('N')), @tolerance_cd
, isnull(@inv_master_reg_prod,(0)), @inv_master_warranty_length
, @inv_master_call_limit, isnull(@pur_prod_flag,('N')), @c_country_desc
, @cmdty_code, @min_profit_perc, @height, @width, @length, @sku_code
, isnull(@inv_master_eprocurement_flag,(0))
, isnull(@inv_master_non_sellable_flag,('N')), @so_qty_increment
)

end
if @typ = 'U'
begin
update inv_master set
inv_master.upc_code= @upc_code, inv_master.sku_no= @sku_no
, inv_master.description= @description, inv_master.vendor= @vendor_key
, inv_master.category= @category, inv_master.type_code= @c_type_code
, inv_master.status= @status, inv_master.cubic_feet= @cubic_feet
, inv_master.weight_ea= @weight_ea, inv_master.labor= @labor
, inv_master.uom= @uom, inv_master.account= @account
, inv_master.comm_type= @c_comm_type, inv_master.void= @void
, inv_master.void_who= @void_who, inv_master.void_date= @void_date
, inv_master.entered_who= @entered_who, inv_master.entered_date= @entered_date
, inv_master.std_cost= @std_cost, inv_master.utility_cost= @utility_cost
, inv_master.qc_flag= @qc_flag, inv_master.note= @note
, inv_master.lb_tracking= @lb_tracking, inv_master.rpt_uom= @uom2
, inv_master.freight_unit= @freight_unit, inv_master.taxable= @taxable
, inv_master.freight_class= @c_freight_class
, inv_master.conv_factor= @conv_factor, inv_master.cycle_type= @cycle_type
, inv_master.inv_cost_method= @inv_cost_method, inv_master.buyer= @c_buyer
, inv_master.allow_fractions= @allow_fractions, inv_master.cfg_flag= @cfg_flag
, inv_master.tax_code= @tax_code, inv_master.obsolete= @obsolete
, inv_master.serial_flag= @serial_flag
, inv_master.web_saleable_flag= @web_saleable_flag
, inv_master.tolerance_cd= @tolerance_cd
, inv_master.reg_prod= @inv_master_reg_prod
, inv_master.warranty_length= @inv_master_warranty_length
, inv_master.call_limit= @inv_master_call_limit
, inv_master.pur_prod_flag= @pur_prod_flag
, inv_master.country_code= @c_country_desc, inv_master.cmdty_code= @cmdty_code
, inv_master.min_profit_perc= @min_profit_perc, inv_master.height= @height
, inv_master.width= @width, inv_master.length= @length
, inv_master.sku_code= @sku_code
, inv_master.eprocurement_flag= @inv_master_eprocurement_flag
, inv_master.non_sellable_flag= @inv_master_non_sellable_flag
, inv_master.so_qty_increment= @so_qty_increment
where inv_master.part_no= @part_no
 and inv_master.timestamp= @ts
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end

end
if @typ = 'D'
begin
delete from inv_master
where inv_master.part_no= @part_no
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Error Deleting Row'
  RETURN 
end

end

return
end
GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_inv_main_sp] TO [public]
GO
