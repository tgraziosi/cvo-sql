SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_auto_drop_ship] @po varchar (16), @qty decimal(20,8), @lot_ser varchar(25), @bin_no varchar(12), @who varchar(50)

AS
 
DECLARE	@order_no int,
	@ext int,
	@location varchar(10), 
	@line_no int, 
	@part_no varchar(30),
	@child int,
	@lb_tracking char(1),
	@err int,
	@conv_factor decimal(20,8),
	@ordered decimal(20,8)

/* Find the first record */
SELECT @err = 0, @order_no = 0 

--IF OBJECT_ID('tempdb..#adm_taxinfo') IS NOT NULL
TRUNCATE TABLE #adm_taxinfo

--IF OBJECT_ID('tempdb..#adm_taxtype') IS NOT NULL
TRUNCATE TABLE #adm_taxtype

--IF OBJECT_ID('tempdb..#adm_taxtyperec') IS NOT NULL
TRUNCATE TABLE #adm_taxtyperec

--IF OBJECT_ID('tempdb..#adm_taxcode') IS NOT NULL
TRUNCATE TABLE #adm_taxcode

--IF OBJECT_ID('tempdb..#cents') IS NOT NULL
TRUNCATE TABLE #cents

SELECT @location = location, @part_no = part_no
  FROM #receipts

SELECT @order_no = order_no, @line_no = line_no
  FROM orders_auto_po (nolock) 
 WHERE po_no = @po
   AND part_no = @part_no

SELECT @ext = max(ext) FROM orders (nolock) WHERE order_no = @order_no AND type = 'I'
SELECT @lb_tracking = lb_tracking FROM inv_master (nolock) WHERE part_no = @part_no

-- SCR #35211  7/22/05
SELECT @ordered = shipped * conv_factor
  FROM ord_list (nolock) 
 WHERE order_no = @order_no 
   AND order_ext = @ext
   AND part_no = @part_no
   AND line_no = @line_no

IF @ordered < 0    SET @ordered = 0
IF @qty > @ordered SET @qty = @ordered

EXEC fs_calculate_oetax @order_no, @ext, @err output

IF (@err < 0) RETURN @err

EXEC fs_updordtots @order_no, @ext

IF (@location = 'DROP')
BEGIN	
	IF EXISTS (SELECT * FROM purchase (nolock) WHERE po_no = @po AND status = 'C')
	BEGIN
		IF EXISTS (SELECT * FROM config (nolock) WHERE flag = 'SHP_AUTO_POST' AND value_str = 'YES')
			EXEC @err = tdc_auto_post_ship @order_no, @ext, NULL, 'Y', 'Y', @who, @err OUTPUT
	END
END
ELSE
BEGIN
	IF (@lb_tracking = 'Y')
	BEGIN
		IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock)
				       WHERE method = '01' 
					 AND order_no = @order_no 
					 AND order_ext = @ext 
					 AND line_no = @line_no
					 AND part_no = @part_no 
					 AND lot_ser = @lot_ser
					 AND bin_no = @bin_no
					 AND [function] = 'S')
		BEGIN
			EXEC @child = tdc_get_serialno

			INSERT INTO tdc_dist_item_pick VALUES('01', @order_no, @ext, @line_no, @part_no, @lot_ser, @bin_no, @qty, @child, 'S', 'O1', null)
		END
		ELSE
		BEGIN
			UPDATE tdc_dist_item_pick
			   SET quantity = quantity + @qty
			 WHERE method = '01' 
			   AND order_no = @order_no 
			   AND order_ext = @ext 
			   AND line_no = @line_no
			   AND part_no = @part_no 
			   AND lot_ser = @lot_ser 
			   AND bin_no = @bin_no 
			   AND [function] = 'S'
		END
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) 
				       WHERE method = '01' 
					 AND order_no = @order_no 
					 AND order_ext = @ext 
					 AND line_no = @line_no 
					 AND part_no = @part_no 
					 AND [function] = 'S')
		BEGIN
			EXEC @child = tdc_get_serialno
	
			INSERT INTO tdc_dist_item_pick VALUES('01', @order_no, @ext, @line_no, @part_no, null, null, @qty, @child, 'S', 'O1', null)			
		END
		ELSE
		BEGIN
			UPDATE tdc_dist_item_pick
			   SET quantity = quantity + @qty
			 WHERE method = '01' 
			   AND order_no = @order_no 
			   AND order_ext = @ext 
			   AND line_no = @line_no
			   AND part_no = @part_no 
			   AND [function] = 'S'
		END
	END
	
	IF(@@ERROR != 0)
	BEGIN
		IF(@@TRANCOUNT > 0) ROLLBACK TRAN
		RETURN -101
	END

	UPDATE tdc_dist_item_list
	   SET shipped = shipped + @qty
	 WHERE order_no = @order_no 
	   AND order_ext = @ext 
	   AND line_no = @line_no
	   AND part_no = @part_no
	   AND [function] = 'S'

	IF(@@ERROR != 0)
	BEGIN
		IF(@@TRANCOUNT > 0) ROLLBACK TRAN
		RETURN -101
	END
END

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_auto_drop_ship] TO [public]
GO
