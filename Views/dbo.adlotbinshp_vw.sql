SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adlotbinshp_vw] as
  SELECT   dbo.lot_bin_ship.part_no ,
           dbo.lot_bin_ship.location , 
           dbo.lot_bin_ship.line_no ,
           dbo.lot_bin_ship.tran_no ,
           dbo.lot_bin_ship.tran_ext ,
           dbo.lot_bin_ship.bin_no ,
           dbo.lot_bin_ship.lot_ser ,
           dbo.lot_bin_ship.date_tran ,
           dbo.lot_bin_ship.date_expires ,
           dbo.lot_bin_ship.qty ,
           dbo.lot_bin_ship.uom ,
 dbo.lot_bin_ship.uom_qty,

 x_line_no=dbo.lot_bin_ship.line_no ,
 x_tran_no=dbo.lot_bin_ship.tran_no ,
 x_tran_ext=dbo.lot_bin_ship.tran_ext ,
 x_date_tran=dbo.lot_bin_ship.date_tran ,
 x_date_expires=dbo.lot_bin_ship.date_expires ,
 x_qty=dbo.lot_bin_ship.qty ,
 x_uom_qty=dbo.lot_bin_ship.uom_qty 

        FROM dbo.lot_bin_ship  

GO
GRANT REFERENCES ON  [dbo].[adlotbinshp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adlotbinshp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adlotbinshp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adlotbinshp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adlotbinshp_vw] TO [public]
GO
