SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_get_carton_detail_sp]
  @carton_no        int
AS

SELECT carton_no, part_no, lot_ser, pack_qty, serial_no, serial_no_raw, version_no, warranty_track 
FROM tdc_carton_detail_tx (nolock)
WHERE carton_no = @carton_no
GO
GRANT EXECUTE ON  [dbo].[tdc_get_carton_detail_sp] TO [public]
GO
