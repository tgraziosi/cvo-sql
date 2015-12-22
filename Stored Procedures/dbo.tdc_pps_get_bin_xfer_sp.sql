SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_pps_get_bin_xfer_sp]
	@packing_flg	int,
	@tote_bin	varchar(12),
	@xfer_no	int,
	@carton_no	int,
	@line_no	int,
	@part_no	varchar(30),	
	@location	varchar(10),
	@lot_ser	varchar(25),
	@bin_no		varchar(12) OUTPUT

AS 

DECLARE @Cnt 		int

IF @packing_flg = 1
BEGIN	
	IF @tote_bin = ''
	BEGIN
		SELECT @cnt = COUNT(*) 
		  FROM tdc_dist_item_pick (NOLOCK)
		 WHERE order_no   = @xfer_no
		   AND order_ext  = 0
	           AND line_no    = @line_no		   
		   AND part_no    = @part_no 
		   AND lot_ser    = @lot_ser
		   AND [function] = 'T'
		IF @cnt > 1 
		BEGIN
			SELECT @bin_no = 'MULTIPLE'
		END
		ELSE
		BEGIN
			SELECT TOP 1 @bin_no = bin_no  
	 		  FROM tdc_dist_item_pick (NOLOCK)
			 WHERE order_no   = @xfer_no
			   AND order_ext  = 0
		           AND line_no    = @line_no		   
			   AND part_no    = @part_no 
			   AND lot_ser    = @lot_ser
			   AND [function] = 'T'
		END
	END
	ELSE --TOTE BINS
	BEGIN
		SELECT @cnt = COUNT(*) 
		  FROM tdc_tote_bin_tbl(NOLOCK)
		 WHERE bin_no     = @tote_bin
		   AND order_no   = @xfer_no
		   AND order_ext  = 0
		   AND location   = @location
		   AND line_no    = @line_no
		   AND part_no    = @part_no
		   AND lot_ser    = @lot_ser
		   AND order_type = 'T'

		IF @cnt > 1 
		BEGIN
			SELECT @bin_no = 'MULTIPLE'
		END
		ELSE
		BEGIN
			SELECT TOP 1 @bin_no = bin_no  
			  FROM tdc_tote_bin_tbl(NOLOCK)
			 WHERE bin_no     = @tote_bin
			   AND order_no   = @xfer_no
			   AND order_ext  = 0
			   AND location   = @location
			   AND line_no    = @line_no
			   AND part_no    = @part_no
			   AND lot_ser    = @lot_ser
			   AND order_type = 'T'
		END
	END

END
ELSE --Unpacking
BEGIN
		SELECT @cnt = COUNT(DISTINCT b.bin_no)
		  FROM tdc_carton_detail_tx a (NOLOCK),
		       tdc_dist_item_pick   b (NOLOCK),
		       tdc_dist_group       c (NOLOCK)
		 WHERE a.order_no 	  = b.order_no
		   AND a.order_ext 	  = b.order_ext
		   AND a.line_no 	  = b.line_no
		   AND c.parent_serial_no = a.carton_no
		   AND c.child_serial_no  = b.child_serial_no
		   AND a.carton_no 	  = @carton_no
		   AND a.order_no 	  = @xfer_no
		   AND a.order_ext 	  = 0
		   AND a.line_no 	  = @line_no
		   AND b.lot_ser 	  = @lot_ser
		   AND a.lot_ser	  = b.lot_ser
		   AND b.[function]	  = 'T'
	IF @cnt = 1
	BEGIN

		SELECT TOP 1 @bin_no = b.bin_no 
		  FROM tdc_carton_detail_tx a (NOLOCK),
		       tdc_dist_item_pick   b (NOLOCK),
		       tdc_dist_group       c (NOLOCK)
		 WHERE a.order_no 	  = b.order_no
		   AND a.order_ext 	  = b.order_ext
		   AND a.line_no 	  = b.line_no
		   AND c.parent_serial_no = a.carton_no
		   AND c.child_serial_no  = b.child_serial_no
		   AND a.carton_no 	  = @carton_no
		   AND a.order_no 	  = @xfer_no
		   AND a.order_ext 	  = 0
		   AND a.line_no 	  = @line_no
		   AND b.lot_ser 	  = @lot_ser
		   AND a.lot_ser	  = b.lot_ser
		   AND b.[function]	  = 'T'
	END
	ELSE
		SELECT @bin_no = 'MULTIPLE'

END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_get_bin_xfer_sp] TO [public]
GO
