SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[adm_copy_loc_sp] 
			@loc_source varchar(10),
			@loc_dest varchar (10),
			@part_no_from varchar(30),
			@part_no_to varchar(30),
			@vendor_from varchar(12),
			@vendor_to varchar(12),
			@type_from varchar(10),
			@type_to varchar(10),
			@master int,
			@cbx_i int,
			@cbx_t int,
			@cbx_v int
		as

  
if @master = 0 
BEGIN
	INSERT INTO inv_list
	( a.part_no,a.location,a.bin_no,a.avg_cost,a.avg_direct_dolrs,
	a.avg_ovhd_dolrs,a.avg_util_dolrs,a.in_stock,a.hold_qty,a.min_stock,a.max_stock,
	a.min_order,a.issued_mtd,a.issued_ytd,a.lead_time,a.status,a.labor,
	a.qty_year_end,a.qty_month_end,a.qty_physical,a.entered_who,a.entered_date,a.void,
	a.void_who,a.void_date,a.std_cost,a.std_labor,a.std_direct_dolrs,a.std_ovhd_dolrs,
	a.std_util_dolrs,a.setup_labor,a.freight_unit,a.note,a.cycle_date,a.acct_code,a.eoq,
	a.dock_to_stock,a.order_multiple,a.abc_code,
	a.abc_code_frozen_flag,a.rank_class,a.po_uom,a.so_uom ) 
	SELECT
	a.part_no,@loc_dest,a.bin_no,0,0,
	0,0,0,a.hold_qty,a.min_stock,a.max_stock,
	a.min_order,0,0,a.lead_time,a.status,a.labor,
	0,0,0,'',getdate(),'N',					-- mls 6/15/04 SCR 33019
	NULL,NULL,a.std_cost,a.std_labor,a.std_direct_dolrs,a.std_ovhd_dolrs,
	a.std_util_dolrs,a.setup_labor,a.freight_unit,a.note,a.cycle_date,a.acct_code,a.eoq,
	a.dock_to_stock,a.order_multiple,a.abc_code,
	a.abc_code_frozen_flag,a.rank_class,a.po_uom,a.so_uom 
	from inv_list a, inv_master b
	where a.location = @loc_source
	AND ((a.part_no between @part_no_from AND @part_no_to ) OR 1 = @cbx_i)
	AND ((b.vendor between @vendor_from AND @vendor_to ) OR 1 = @cbx_v)
	AND ((b.type_code between @type_from AND @type_to) OR 1 = @cbx_t)
	AND a.part_no = b.part_no 
	AND a.part_no  NOT IN( SELECT part_no FROM inv_list WHERE location = @loc_dest ) 










END

IF @master  = 1 
BEGIN
 
	INSERT INTO inv_list
	( a.part_no,a.location,a.bin_no,a.avg_cost,a.avg_direct_dolrs,
	a.avg_ovhd_dolrs,a.avg_util_dolrs,a.in_stock,a.hold_qty,a.min_stock,a.max_stock,
	a.min_order,a.issued_mtd,a.issued_ytd,a.lead_time,a.status,a.labor,
	a.qty_year_end,a.qty_month_end,a.qty_physical,a.entered_who,a.entered_date,a.void,
	a.void_who,a.void_date,a.std_cost,a.std_labor,a.std_direct_dolrs,a.std_ovhd_dolrs,
	a.std_util_dolrs,a.setup_labor,a.freight_unit,a.note,a.cycle_date,a.acct_code,a.eoq,
	a.dock_to_stock,a.order_multiple,a.abc_code,
	a.abc_code_frozen_flag,a.rank_class,a.po_uom,a.so_uom ) 
	SELECT
	distinct a.part_no,@loc_dest,'N/A',0,0,
	0,0,0,0,0,0.0,
	0.0,0,0,0,a.status,0,
	0,0,0,'',getdate(),'N',					-- mls 6/15/04 SCR 33019
	NULL,NULL,0,0,0,0,
	0,a.setup_labor,a.freight_unit,NULL,'',b.account ,0,
	0,0.0,a.abc_code,
	a.abc_code_frozen_flag,'N',b.uom,b.uom 
	from inv_list a, inv_master b
	where ((a.part_no between @part_no_from AND @part_no_to ) OR 1= @cbx_i )
	AND ((b.vendor between @vendor_from AND @vendor_to ) OR 1 = @cbx_v)
	AND ((b.type_code between @type_from AND @type_to ) OR 1 = @cbx_t )
	AND (a.part_no = b.part_no) 
	AND   a.part_no  NOT IN ( SELECT part_no FROM inv_list WHERE location =@loc_dest )

	INSERT INTO inv_xfer (a.part_no, a.location, a.commit_ed,a.xfer_mtd, a.xfer_ytd, a.hold_xfr, a.transit,a.commit_to_loc)
	SELECT distinct a.part_no, @loc_dest, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
	FROM inv_xfer a, inv_master b
	WHERE  ((a.part_no between @part_no_from AND @part_no_to ) OR 1 = @cbx_i)
	AND ((b.vendor between @vendor_from AND @vendor_to ) OR 1 = @cbx_v)
	AND ((b.type_code between @type_from AND @type_to ) OR 1 = @cbx_t)
	AND (a.part_no = b.part_no) 
	AND   a.part_no  NOT IN ( SELECT part_no FROM inv_xfer WHERE location = @loc_dest )

END
GO
GRANT EXECUTE ON  [dbo].[adm_copy_loc_sp] TO [public]
GO
