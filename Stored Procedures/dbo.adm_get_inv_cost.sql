SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 21/04/2015 - Performance Changes  
  
CREATE PROCEDURE [dbo].[adm_get_inv_cost] @part_no varchar(30) OUT, @location varchar(10) OUT,  
    @use_ac char(1) OUT, @in_stock decimal(20,8) OUT, @inv_holds decimal(20,8) OUT, @non_holds decimal(20,8) OUT,   
    @typ char(1) OUT, @status char(1) OUT, @acct_code varchar(8) OUT, @std_uom char(2) OUT,  
    @a_avg_cost decimal(20,8) OUT, @a_direct_dolrs decimal(20,8) OUT, @a_ovhd_dolrs decimal(20,8) OUT,   
    @a_util_dolrs decimal(20,8) OUT, @a_labor decimal(20,8) OUT,  
    @s_std_cost decimal(20,8) OUT, @s_direct_dolrs decimal(20,8) OUT, @s_ovhd_dolrs decimal(20,8) OUT,   
    @s_util_dolrs decimal(20,8) OUT, @s_labor decimal(20,8) OUT,  
    @cl_qty decimal(20,8) OUT  
 as  
begin  
  
  select   
    @use_ac = 'Y', --isnull((select 'Y' from config (nolock) where flag = 'INV_USE_AVG_COST' and value_str like 'Y%'),'N'),  
    @in_stock = i.in_stock,  
    @inv_holds = i.hold_ord + i.hold_xfr,  
    @non_holds = 0,  
    @typ = i.inv_cost_method,   
    @status = i.status,  
    @acct_code = i.acct_code,  
    @std_uom = i.uom,  
    @a_avg_cost = avg_cost,   @a_direct_dolrs = avg_direct_dolrs,  @a_ovhd_dolrs = avg_ovhd_dolrs,   
    @a_util_dolrs = avg_util_dolrs, @a_labor = 0,  
    @s_std_cost = i.std_cost, @s_direct_dolrs = std_direct_dolrs,  @s_ovhd_dolrs = std_ovhd_dolrs,     
    @s_util_dolrs = std_util_dolrs, @s_labor = std_labor,  
    @cl_qty = isnull((select sum(balance) from inv_costing c (nolock) where c.part_no = i.part_no and  
      c.location = i.location and c.account = 'STOCK'),0),  
    @part_no = i.part_no,  
    @location = i.location  
  from cvo_inventory2 i -- v1.0 
  where i.part_no =  @part_no and i.location = @location  
  
  if @@rowcount = 0 or @@error != 0  
    return -1  
  
  return 1  
end  
GO
GRANT EXECUTE ON  [dbo].[adm_get_inv_cost] TO [public]
GO
