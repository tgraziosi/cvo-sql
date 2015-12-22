SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[scm_pb_set_dw_new_inv_list_sp] 
@typ char(1), @location varchar(10), @part_no varchar(30), @bin_no varchar(12)
, @avg_cost decimal(20,8), @in_stock decimal(20,8), @min_stock decimal(20,8)
, @min_order decimal(20,8), @lead_time integer, @labor decimal(20,8)
, @issued_mtd decimal(20,8), @issued_ytd decimal(20,8), @hold_qty decimal(20,8)
, @qty_year_end decimal(20,8), @qty_month_end decimal(20,8)
, @qty_physical decimal(20,8), @entered_who varchar(20), @entered_date datetime
, @void char(1), @void_who varchar(20), @void_date datetime
, @std_cost decimal(20,8), @max_stock decimal(20,8), @setup_labor decimal(20,8)
, @note varchar(255), @freight_unit decimal(20,8), @std_labor decimal(20,8)
, @account varchar(8), @std_direct_dolrs decimal(20,8)
, @std_ovhd_dolrs decimal(20,8), @std_util_dolrs decimal(20,8)
, @avg_direct_dolrs decimal(20,8), @avg_ovhd_dolrs decimal(20,8)
, @avg_util_dolrs decimal(20,8), @cycle_date datetime, @status char(1)
, @eoq decimal(20,8), @dock_to_stock integer, @order_multiple decimal(20,8)
, @inventory_in_stock decimal(20,8), @inventory_committed decimal(20,8)
, @inventory_hold_qty decimal(20,8), @inventory_qty_alloc decimal(20,8)
, @inventory_po_on_order decimal(20,8), @inventory_issued_mtd decimal(20,8)
, @inventory_issued_ytd decimal(20,8), @inventory_recv_mtd decimal(20,8)
, @inventory_recv_ytd decimal(20,8), @inventory_usage_mtd decimal(20,8)
, @inventory_usage_ytd decimal(20,8), @inventory_sales_qty_mtd decimal(20,8)
, @inventory_sales_qty_ytd decimal(20,8), @inventory_last_recv_date datetime
, @inventory_oe_on_order decimal(20,8), @inventory_qty_scheduled decimal(20,8)
, @inventory_produced_mtd decimal(20,8), @inventory_produced_ytd decimal(20,8)
, @inventory_sales_amt_mtd decimal(20,8), @inventory_sales_amt_ytd decimal(20,8)
, @inventory_hold_mfg decimal(20,8), @inventory_hold_ord decimal(20,8)
, @inventory_hold_rcv decimal(20,8), @inventory_hold_xfr decimal(20,8)
, @inventory_cost decimal(20,8), @inventory_last_cost decimal(20,8)
, @inventory_sch_alloc decimal(20,8), @inventory_sch_date datetime
, @c_sort decimal(20,8), @inventory_transit decimal(20,8)
, @inv_xfer_commit_ed decimal(20,8), @inventory_xfer_mtd decimal(20,8)
, @inventory_xfer_ytd decimal(20,8), @c_allocated_amt decimal(20,8)
, @c_quarantined_amt decimal(20,8), @c_barcoded char(1)
, @inv_list_rank_class char(1), @inv_list_po_uom varchar(2)
, @inv_list_so_uom varchar(2), @clast_count_date datetime
, @cvendor_code varchar(12), @inv_turns decimal(20,6)
, @inv_list_qc_qty decimal(20,8), @inv_list_so_qty_increment decimal(20,8)
, @organization_id varchar(30), @timestamp varchar(20)
 AS
BEGIN
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
Insert into inv_list (inv_list.location, inv_list.part_no, inv_list.bin_no, inv_list.avg_cost
, inv_list.in_stock, inv_list.min_stock, inv_list.min_order, inv_list.lead_time
, inv_list.labor, inv_list.issued_mtd, inv_list.issued_ytd, inv_list.hold_qty
, inv_list.qty_year_end, inv_list.qty_month_end, inv_list.qty_physical
, inv_list.entered_who, inv_list.entered_date, inv_list.void, inv_list.void_who
, inv_list.void_date, inv_list.std_cost, inv_list.max_stock
, inv_list.setup_labor, inv_list.note, inv_list.freight_unit, inv_list.std_labor
, inv_list.acct_code, inv_list.std_direct_dolrs, inv_list.std_ovhd_dolrs
, inv_list.std_util_dolrs, inv_list.avg_direct_dolrs, inv_list.avg_ovhd_dolrs
, inv_list.avg_util_dolrs, inv_list.cycle_date, inv_list.status, inv_list.eoq
, inv_list.dock_to_stock, inv_list.order_multiple, inv_list.rank_class
, inv_list.po_uom, inv_list.so_uom, inv_list.so_qty_increment
)
values (@location, @part_no, @bin_no, @avg_cost, @in_stock, @min_stock
, isnull(@min_order,(0)), @lead_time, @labor, @issued_mtd, @issued_ytd
, @hold_qty, @qty_year_end, @qty_month_end, @qty_physical, @entered_who
, @entered_date, isnull(@void,('N')), @void_who, @void_date, @std_cost
, @max_stock, @setup_labor, @note, isnull(@freight_unit,(0))
, isnull(@std_labor,(0)), @account, isnull(@std_direct_dolrs,(0))
, isnull(@std_ovhd_dolrs,(0)), isnull(@std_util_dolrs,(0))
, isnull(@avg_direct_dolrs,(0)), isnull(@avg_ovhd_dolrs,(0))
, isnull(@avg_util_dolrs,(0)), @cycle_date, @status, @eoq
, isnull(@dock_to_stock,(0)), isnull(@order_multiple,(0)), @inv_list_rank_class
, @inv_list_po_uom, @inv_list_so_uom, @inv_list_so_qty_increment
)
end
if @typ = 'U'
begin
update inv_list set
inv_list.bin_no= @bin_no, inv_list.avg_cost= @avg_cost
, inv_list.in_stock= @in_stock, inv_list.min_stock= @min_stock
, inv_list.min_order= @min_order, inv_list.lead_time= @lead_time
, inv_list.labor= @labor, inv_list.issued_mtd= @issued_mtd
, inv_list.issued_ytd= @issued_ytd, inv_list.hold_qty= @hold_qty
, inv_list.qty_year_end= @qty_year_end, inv_list.qty_month_end= @qty_month_end
, inv_list.qty_physical= @qty_physical, inv_list.entered_who= @entered_who
, inv_list.entered_date= @entered_date, inv_list.void= @void
, inv_list.void_who= @void_who, inv_list.void_date= @void_date
, inv_list.std_cost= @std_cost, inv_list.max_stock= @max_stock
, inv_list.setup_labor= @setup_labor, inv_list.note= @note
, inv_list.freight_unit= @freight_unit, inv_list.std_labor= @std_labor
, inv_list.acct_code= @account, inv_list.std_direct_dolrs= @std_direct_dolrs
, inv_list.std_ovhd_dolrs= @std_ovhd_dolrs
, inv_list.std_util_dolrs= @std_util_dolrs
, inv_list.avg_direct_dolrs= @avg_direct_dolrs
, inv_list.avg_ovhd_dolrs= @avg_ovhd_dolrs
, inv_list.avg_util_dolrs= @avg_util_dolrs, inv_list.cycle_date= @cycle_date
, inv_list.status= @status, inv_list.eoq= @eoq
, inv_list.dock_to_stock= @dock_to_stock
, inv_list.order_multiple= @order_multiple
, inv_list.rank_class= @inv_list_rank_class, inv_list.po_uom= @inv_list_po_uom
, inv_list.so_uom= @inv_list_so_uom
, inv_list.so_qty_increment= @inv_list_so_qty_increment
where inv_list.location= @location and inv_list.part_no= @part_no
 and inv_list.timestamp= @ts
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end

end
if @typ = 'D'
begin
delete from inv_list
where inv_list.location= @location and inv_list.part_no= @part_no
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
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_new_inv_list_sp] TO [public]
GO
