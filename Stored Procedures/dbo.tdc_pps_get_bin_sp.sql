SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_pps_get_bin_sp]
	@is_packing	char(1),
	@carton_no	int,
	@tote_bin	varchar(12),
	@order_no	int,
	@order_ext	int,	
	@line_no	int,
	@part_no	varchar(30),
	@kit_item	varchar(30),
	@location	varchar(10),
	@lot_ser	varchar(25),
	@bin_no		varchar(12) OUTPUT,
	@tran_id	int	= -1  --OPTIONAL PARAMETER

AS 

DECLARE @Cnt 		int 

IF @is_packing = 'Y'
BEGIN
	IF @tote_bin = ''
	BEGIN
		--Retrieve the bin from the pick table
		IF (@kit_item = '') --Not a custom kit
		BEGIN
			IF @tran_id = -1
			BEGIN
				SELECT @cnt = COUNT(DISTINCT bin_no) 
				  FROM tdc_dist_item_pick (NOLOCK)
				 WHERE order_no  = @order_no
				   AND order_ext = @order_ext
				   AND line_no   = @line_no
				   AND part_no   = @part_no 
				   AND lot_ser   = @lot_ser
				   AND quantity <> 0
	
				IF @cnt > 1 
				BEGIN
					SELECT @bin_no = 'MULTIPLE'
				END
				ELSE
				BEGIN
					SELECT TOP 1 @bin_no = ISNULL(bin_no, @bin_no)
					  FROM tdc_dist_item_pick (NOLOCK)
					 WHERE order_no      = @order_no
					   AND order_ext     = @order_ext
					   AND line_no       = @line_no
					   AND part_no       = @part_no 
					   AND lot_ser       = @lot_ser
					   AND quantity	    <> 0
				END
			END
			ELSE
			BEGIN
				--VERIFY USING THE TRAN_ID
				IF EXISTS(SELECT bin_no FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id)
				BEGIN
					SELECT @bin_no = bin_no FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
				END
				ELSE
					SELECT @bin_no = ''
			END
		END
		ELSE
		BEGIN
			-- SCR #36087  Jim 1/25/06  Begin
			SELECT @cnt = COUNT(DISTINCT bin_no)
			  FROM lot_bin_ship(NOLOCK)
			 WHERE bin_no in (
					SELECT DISTINCT a.bin_no
					  FROM lot_bin_ship a (NOLOCK)
				 	 WHERE a.tran_no	= @order_no
					   AND a.tran_ext 	= @order_ext
					   AND a.line_no   	= @line_no
					   AND a.part_no   	= @kit_item
					   AND a.lot_ser	= @lot_ser
					 GROUP BY a.tran_no, a.tran_ext, a.line_no, a.part_no, a.lot_ser, a.bin_no
					HAVING SUM(a.qty) > ISNULL((SELECT SUM(b.qty) 
								  FROM tdc_custom_kits_packed_tbl b (NOLOCK)
								 WHERE carton_no = @carton_no
								   AND b.order_no = @order_no
								   AND b.order_ext = @order_ext
								   AND b.line_no  = @line_no
								   AND (b.kit_part_no = @kit_item OR b.sub_kit_part_no  = @kit_item)
								   AND b.lot_ser  = @lot_ser
								   AND a.bin_no   = b.bin_no ), 0))
								-- GROUP BY a.tran_no, a.tran_ext, a.line_no, a.part_no, a.lot_ser, a.bin_no),0))
	
			IF ISNULL(@cnt, 0) > 1 
			BEGIN
				SELECT @bin_no = 'MULTIPLE'
			END
			ELSE
			BEGIN
				SELECT TOP 1 @bin_no = a.bin_no
				  FROM lot_bin_ship a(NOLOCK)
			 	 WHERE a.tran_no        = @order_no
				   AND a.tran_ext 	= @order_ext
				   AND a.line_no   	= @line_no
				   AND a.part_no   	= @kit_item
				   AND a.lot_ser	= @lot_ser
				 GROUP BY a.tran_no, a.tran_ext, a.line_no, a.part_no, a.lot_ser, a.bin_no 
				HAVING SUM(a.qty) > ISNULL((SELECT SUM(qty) 
							  FROM tdc_custom_kits_packed_tbl b (NOLOCK)
							 WHERE carton_no = @carton_no
							   AND b.order_no = @order_no
							   AND b.order_ext = @order_ext
							   AND b.line_no  = @line_no
							   AND (b.kit_part_no = @kit_item OR b.sub_kit_part_no  = @kit_item)
							   AND b.lot_ser  = @lot_ser
							   AND a.bin_no   = b.bin_no ), 0)
							-- GROUP BY a.tran_no, a.tran_ext, a.line_no, a.part_no, a.lot_ser, a.bin_no),0)
			END				 
			-- SCR #36087  Jim 1/25/06  End
		END
	END 
	ELSE --TOTE BIN
	BEGIN
		IF @kit_item = ''
		BEGIN
			SELECT @cnt = COUNT(*) 
			  FROM tdc_tote_bin_tbl(NOLOCK)
			 WHERE bin_no     = @tote_bin
			   AND order_no   = @order_no
			   AND order_ext  = @order_ext
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
				   AND order_no   = @order_no
				   AND order_ext  = @order_ext
				   AND location   = @location
				   AND line_no    = @line_no
				   AND part_no    = @part_no
				   AND lot_ser    = @lot_ser
				   AND order_type = 'T'
			END
		END
		ELSE --Custom Kits
		BEGIN
			SELECT @cnt = COUNT(*) 
			  FROM tdc_tote_bin_tbl(NOLOCK)
			 WHERE bin_no     = @tote_bin
			   AND order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND location   = @location
			   AND line_no    = @line_no
			   AND part_no    = @kit_item
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
				   AND order_no   = @order_no
				   AND order_ext  = @order_ext
				   AND location   = @location
				   AND line_no    = @line_no
				   AND part_no    = @kit_item
				   AND lot_ser    = @lot_ser
				   AND order_type = 'T'
			END
		END
	END --TOTE BIN
	 
END
ELSE --Unpacking
BEGIN

	IF (@kit_item = '') --Not a custom kit
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
		   AND a.order_no 	  = @order_no
		   AND a.order_ext 	  = @order_ext
		   AND a.line_no 	  = @line_no
		   AND b.lot_ser 	  = @lot_ser
		   AND a.lot_ser	  = b.lot_ser
 
		IF @cnt = 1
		BEGIN

			SELECT TOP 1 @bin_no      = b.bin_no 
			  FROM tdc_carton_detail_tx a (NOLOCK),
			       tdc_dist_item_pick   b (NOLOCK),
			       tdc_dist_group 	    c (NOLOCK)
			 WHERE a.order_no 	  = b.order_no
			   AND a.order_ext 	  = b.order_ext
			   AND a.line_no 	  = b.line_no
			   AND c.parent_serial_no = a.carton_no
			   AND c.child_serial_no  = b.child_serial_no
			   AND a.carton_no 	  = @carton_no
			   AND a.order_no 	  = @order_no
			   AND a.order_ext 	  = @order_ext
			   AND a.line_no 	  = @line_no
			   AND b.lot_ser 	  = @lot_ser
			   AND a.lot_ser	  = b.lot_ser
		END
		ELSE
			SELECT @bin_no = 'MULTIPLE'
	END
	ELSE
	BEGIN

		SELECT @cnt = COUNT(DISTINCT bin_no) 
		  FROM tdc_custom_kits_packed_tbl (NOLOCK)                                 
		 WHERE carton_no    = @carton_no
		   AND (kit_part_no = @kit_item OR sub_kit_part_no = @kit_item)
		   AND line_no	    = @line_no
		   AND lot_ser      = @lot_ser

		IF @cnt = 1
		BEGIN
			SELECT TOP 1 @bin_no = bin_no
			  FROM tdc_custom_kits_packed_tbl (NOLOCK)                                 
			 WHERE carton_no    = @carton_no
			   AND (kit_part_no = @kit_item OR sub_kit_part_no = @kit_item)
			   AND line_no	    = @line_no
			   AND lot_ser      = @lot_ser
		END
		ELSE
			SELECT @bin_no = 'MULTIPLE'
	END
END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_get_bin_sp] TO [public]
GO
