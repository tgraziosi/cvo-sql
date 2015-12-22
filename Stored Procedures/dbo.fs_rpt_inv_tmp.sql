SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_rpt_inv_tmp] @part varchar(30),@type varchar(10), 
	@cat varchar(10), @loc varchar(10), @cost char(1), @stat char(1) AS

declare @minstat char(1)
declare @maxstat char(1)
  SELECT @minstat = 'A' 
  SELECT @maxstat = 'Q'
  if @stat = 'P' begin
    SELECT @minstat = 'N'
  end
  if @stat = 'M' begin
    SELECT @maxstat = 'M'
  end
  SELECT dbo.inventory.part_no,   
         dbo.inventory.description,   

         dbo.inventory.type_code,   
         dbo.inventory.in_stock,   
         dbo.inventory.po_on_order,   
         dbo.inventory.qty_alloc,   
         dbo.inventory.min_stock,   
         dbo.inventory.min_order,
         dbo.inventory.commit_ed + dbo.inventory.sch_alloc comm_and_alloc,
         dbo.inventory.recv_mtd,   
         dbo.inventory.issued_mtd,   
         dbo.inventory.usage_mtd,   
         dbo.inventory.sales_qty_mtd,   
         dbo.inventory.recv_ytd,   
         dbo.inventory.issued_ytd,   
         dbo.inventory.usage_ytd,   
         dbo.inventory.sales_qty_ytd,   
         convert(datetime, '01/01/90 00:00:00') todays_date,
         dbo.inventory.vendor,   
         dbo.inventory.cost,   
         dbo.inventory.avg_cost,   
         dbo.inventory.last_cost,   
         dbo.inventory.sales_amt_mtd,   
         dbo.inventory.sales_amt_ytd,   
         dbo.inventory.oe_on_order,   
         dbo.inventory.hold_mfg,   
         dbo.inventory.hold_ord,   
         dbo.inventory.hold_rcv + dbo.inventory.hold_qty hold_total,   
         dbo.inventory.hold_xfr,   
         dbo.inventory.avg_direct_dolrs,   
         dbo.inventory.avg_ovhd_dolrs,   
         dbo.inventory.avg_util_dolrs,   
         dbo.inventory.avg_cost + dbo.inventory.avg_direct_dolrs + dbo.inventory.avg_ovhd_dolrs + dbo.inventory.avg_util_dolrs avg_cost_and_ovhd,
         dbo.inventory.location,   
         dbo.inventory.std_cost,   
         dbo.inventory.std_direct_dolrs,   
         dbo.inventory.std_ovhd_dolrs,   
         dbo.inventory.std_util_dolrs,   
         dbo.inventory.labor,   
         dbo.inventory.std_labor,   
         dbo.inventory.std_cost + dbo.inventory.std_direct_dolrs + dbo.inventory.avg_ovhd_dolrs + dbo.inventory.std_util_dolrs std_cost_and_ovhd,   
         @part parm_part,   
         @type parm_type,
         @cat  parm_cat,   
         @loc  parm_loc,   
         @cost parm_cost, 
	 @stat parm_stat
    FROM dbo.inventory  
   WHERE ( dbo.inventory.status >= @minstat AND
	   dbo.inventory.status <= @maxstat ) AND
	 ( @part = '%' OR dbo.inventory.part_no like @part ) AND  
         ( @type = '%' OR dbo.inventory.type_code like @type ) AND  
         ( @cat = '%' OR dbo.inventory.category like @cat ) AND  
         ( @loc = '%' OR dbo.inventory.location like @loc ) AND
         ( inventory.void is null OR inventory.void = 'N' )  
ORDER BY dbo.inventory.location ASC,   
         dbo.inventory.part_no ASC
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_inv_tmp] TO [public]
GO
