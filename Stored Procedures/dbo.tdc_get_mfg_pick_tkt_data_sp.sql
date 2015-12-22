SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_mfg_pick_tkt_data_sp] (
  @prod_no int, 
  @prod_ext int, 
  @data_type varchar(1),
  @User_ID varchar(50)
  )
AS

if (@data_type = 'H')
BEGIN
select  DISTINCT 
    a.location, prod_plus_ext = convert(varchar(8), a.prod_no)  + '-' + convert(varchar(8), a.prod_ext ),  
    a.prod_no, a.part_no, a.prod_ext, a.[description], a.note mfg_note, b.note, @User_ID User_id,
    a.date_entered,  a.prod_date, a.sch_date, a.qty_scheduled, a.qty, a.prod_type, a.uom, a.staging_area
	from produce a (NOLOCK), inv_master b (NOLOCK)
	where prod_no = @prod_no
	and prod_ext = @prod_ext
	and a.part_no = b.part_no
END

if (@data_type = 'D')
BEGIN
	SELECT a.line_no, a.seq_no, a.part_no, b.[description], a.uom,  a.plan_qty, a.used_qty, c.lot_ser, c.bin_no, b.note, a.note comment
	FROM prod_list a (NOLOCK), inv_master b (NOLOCK), lot_bin_prod c  (NOLOCK)
	WHERE a.prod_no = @prod_no
	and a.prod_ext = @prod_ext
	and  a.prod_no *=c.tran_no
	and a.prod_ext *= c.tran_ext
	and a.line_no *= c.line_no
	and a.part_no = b.part_no
	and a.direction < 0 
	order by a.Line_no, a.part_no
END

GO
GRANT EXECUTE ON  [dbo].[tdc_get_mfg_pick_tkt_data_sp] TO [public]
GO
