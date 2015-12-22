SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_costvar] @range varchar(8000) = '0=0', 
@order varchar(1000) = 'inventory.part_no'
as
begin

select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

CREATE table  #rpt_costvar ( 
   location varchar(10), 
   part_no varchar(30), 
   part_and_desc varchar(285), 
   description varchar(255) NULL, 
   cost decimal(20,8), 
	 avg_cost decimal(20,8), 
   last_cost decimal(20,8), 
   avg_direct_dolrs decimal(20,8) NULL, 
   avg_ovhd_dolrs decimal(20,8) NULL, 
   avg_util_dolrs decimal(20,8) NULL, 
   in_stock decimal(20,8) NULL, 
   hold_qty decimal(20,8), 
   min_stock decimal(20,8), 
	 qty_alloc decimal(20,8), 
   po_on_order decimal(20,8), 
   vendor varchar(12) NULL, 
   issued_mtd decimal(20,8), 
   issued_ytd decimal(20,8) , 
   recv_mtd decimal(20,8) , 
   recv_ytd decimal(20,8) , 
   category varchar(10) NULL, 
   type_code varchar(10) NULL, 
	 usage_mtd decimal(20,8), 
   usage_ytd decimal(20,8), 
   sales_qty_mtd decimal(20,8), 
   sales_qty_ytd decimal(20,8), 
	 status char(1) NULL, 
   oe_on_order decimal(20,8), 
   labor decimal(20,8), 
   sales_amt_mtd decimal(20,8), 
   sales_amt_ytd decimal(20,8), 
   std_cost decimal(20,8), 
	 std_labor decimal(20,8) NULL, 
	 std_direct_dolrs decimal(20,8) NULL, 
   std_ovhd_dolrs decimal(20,8) NULL, 
   total_avg_cost decimal(20,8) NULL, 
	 total_std_cost decimal(20,8) NULL, 
   std_util_dolrs decimal(20,8) NULL, 
	 average_price decimal(20,8) NULL, 
   cost_variance decimal(20,8) NULL)

declare @sql varchar(8000)

select @sql = 'SELECT distinct inventory.* 
     FROM (select i.location,  
                 i.part_no,  
                 i.part_no + ''\'' + left(i.description,240) partanddesc, 
 	       i.description,    
               i.cost,   
                i.avg_cost,  
                 i.last_cost,   
                 i.avg_direct_dolrs,  
                 i.avg_ovhd_dolrs,  
                i.avg_util_dolrs,    
                 i.in_stock,    
                 i.hold_qty,    
                 i.min_stock,   
                 i.qty_alloc,  
                 i.po_on_order, 
                 i.vendor,   
                 i.issued_mtd, 
                 i.issued_ytd, 
                 i.recv_mtd,   
                 i.recv_ytd,   
                 i.category,   
                 i.type_code,   
                 i.usage_mtd,    
                 i.usage_ytd,    
                 i.sales_qty_mtd,   
                 i.sales_qty_ytd,  
                 i.status, 
                 i.oe_on_order,    
                 i.labor,    
                 i.sales_amt_mtd,    
                 i.sales_amt_ytd, 
                 i.std_cost,    
                 i.std_labor,    
                 i.std_direct_dolrs,  
                 i.std_ovhd_dolrs,    
                 i.avg_cost + i.avg_direct_dolrs + i.avg_ovhd_dolrs + i.avg_util_dolrs total_avg_cost, 
                 i.std_cost + i.std_direct_dolrs + i.std_ovhd_dolrs + i.std_util_dolrs total_std_cost, 
                 i.std_util_dolrs,  
                 case  i.sales_qty_ytd  when 0 then 0 
                   else Round(( i.sales_amt_ytd / i.sales_qty_ytd), 3 ) end average_price , 
                 case (i.std_cost + i.std_direct_dolrs + i.std_ovhd_dolrs + i.std_util_dolrs) 
                   when  0 then case (i.avg_cost + i.avg_direct_dolrs + i.avg_ovhd_dolrs +  
                         i.avg_util_dolrs) when  0 then 0 else  1 end  
                   else  case (i.avg_cost + i.avg_direct_dolrs + i.avg_ovhd_dolrs +  
                         i.avg_util_dolrs) when 0 then 0  
                   else ((i.avg_cost + i.avg_direct_dolrs + i.avg_ovhd_dolrs + i.avg_util_dolrs) 
                       - (i.std_cost + i.std_direct_dolrs + i.std_ovhd_dolrs + i.std_util_dolrs)) /  
                       (i.std_cost + i.std_direct_dolrs + i.std_ovhd_dolrs + i.std_util_dolrs) 
                       * 100 end end cost_variance 
                 from inventory i (nolock)
                 where i.status < ''R'') inventory  , locations l (nolock), region_vw r (nolock)
    where l.location = inventory.location and 
   l.organization_id = r.org_id and ' + @range + '
    ORDER BY ' + @order

print @sql
exec(@sql)
end 
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_costvar] TO [public]
GO
