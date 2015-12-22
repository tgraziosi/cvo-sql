SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_cross_dock_management]
	@location	varchar(10),
	@part_no	varchar(30),
	@lot_ser	varchar(25),
	@bin_no		varchar(12),
	@qty		decimal(20, 8),
	@from_tran_type	char(1),
	@from_tran_no	varchar(16),
	@from_tran_ext	int,
	@remain_qty 	decimal(20, 8) output
AS

	DECLARE @order_no 	int
	DECLARE @order_ext	int
	DECLARE @cd_qty		decimal(20, 8)
	DECLARE @mgt_qty	decimal(20, 8)
	DECLARE @line_no	int
	DECLARE @tran_type	varchar(15)
	DECLARE @target_bin	varchar(12)
	DECLARE @dest_bin	varchar(12)
	DECLARE @tran_id	int
	DECLARE @trg_off	int
	DECLARE @priority 	int
	DECLARE @order_type	char(1)

	SET @tran_id = -1

	SELECT @priority = ISNULL((SELECT value_str FROM tdc_config (nolock) WHERE [function] = 'put_q_priority'), '5')
	IF @priority = '0' SELECT @priority = '5'

	DECLARE cdock_mgt CURSOR FOR
	SELECT que.trans_type_no, que.trans_type_ext, que.qty_to_process, que.line_no, que.trans, que.tran_id
	  FROM tdc_pick_queue que (nolock), tdc_cdock_mgt mgt (nolock)
	 WHERE mgt.from_tran_type = @from_tran_type
	   AND mgt.from_tran_no = @from_tran_no
	   AND que.trans = mgt.tran_type
	   AND que.trans_type_no = mgt.tran_no
	   AND ISNULL(que.trans_type_ext, 0) = ISNULL(mgt.tran_ext, 0)
	   AND que.location = mgt.location
	   AND que.part_no = mgt.part_no
	   AND que.line_no = mgt.line_no
	   AND que.location = @location
	   AND que.part_no = @part_no 
	   AND que.lot = 'CDOCK'
	   AND que.bin_no = 'CDOCK'
	ORDER BY priority, date_time

	OPEN cdock_mgt
	FETCH NEXT FROM cdock_mgt INTO @order_no, @order_ext, @cd_qty, @line_no, @tran_type, @tran_id

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @order_type = SUBSTRING(@tran_type, 1, 1)

		IF(@order_type = 'X') SELECT @order_type = 'T'

		SELECT @mgt_qty = qty
		  FROM tdc_cdock_mgt (nolock) 
		 WHERE from_tran_type = @from_tran_type
		   AND from_tran_no = @from_tran_no
		   AND tran_no  = @order_no 
		   AND ISNULL(tran_ext, 0) = ISNULL(@order_ext, 0)
		   AND location = @location
		   AND line_no  = @line_no
		   AND part_no  = @part_no
		   AND tran_type = @tran_type

		IF (@mgt_qty > @cd_qty)
			SELECT @mgt_qty = @cd_qty

		IF (@mgt_qty > @qty)
		BEGIN
	  		UPDATE tdc_cdock_mgt
			   SET qty = qty - @qty
		 	 WHERE from_tran_type = @from_tran_type
		   	   AND from_tran_no = @from_tran_no
			   AND tran_no = @order_no 
			   AND ISNULL(tran_ext, 0) = ISNULL(@order_ext, 0)
			   AND location = @location
			   AND line_no = @line_no
			   AND part_no = @part_no
			   AND tran_type = @tran_type

			SELECT @mgt_qty = @qty
		END
		ELSE
		BEGIN
  			DELETE FROM tdc_cdock_mgt
		 	 WHERE from_tran_type = @from_tran_type
		   	   AND from_tran_no = @from_tran_no
			   AND tran_no = @order_no 
			   AND ISNULL(tran_ext, 0) = ISNULL(@order_ext, 0)
			   AND location = @location
			   AND line_no = @line_no
			   AND part_no = @part_no
			   AND tran_type = @tran_type
		END

		SELECT @qty = @qty - @mgt_qty

		UPDATE tdc_soft_alloc_tbl
		   SET qty = qty - @mgt_qty
		 WHERE order_no = @order_no
		   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0) 
		   AND line_no = @line_no 
		   AND lot_ser = 'CDOCK' 
		   AND bin_no = 'CDOCK' 
		   AND part_no = @part_no
		   AND order_type = @order_type

		UPDATE tdc_pick_queue 
		   SET qty_to_process = qty_to_process - @mgt_qty
		 WHERE tran_id = @tran_id

		SELECT @target_bin = target_bin, @dest_bin = dest_bin, @trg_off = trg_off
		  FROM tdc_soft_alloc_tbl (nolock)
		 WHERE order_type = @order_type
		   AND order_no = @order_no 
		   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
		   AND location = @location 
		   AND part_no = @part_no 
		   AND lot_ser = 'CDOCK' 
		   AND bin_no = 'CDOCK'

		DELETE FROM tdc_soft_alloc_tbl 
		WHERE order_no = @order_no 
		  AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
		  AND line_no = @line_no
		  AND part_no = @part_no
		  AND lot_ser = 'CDOCK' 
		  AND bin_no = 'CDOCK'
		  AND qty <= 0
			
		DELETE FROM tdc_pick_queue 
		WHERE tran_id = @tran_id
		  AND qty_to_process <= 0

		IF EXISTS (SELECT * 
			     FROM tdc_soft_alloc_tbl
			    WHERE order_type = @order_type
			      AND order_no = @order_no 
			      AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
			      AND location = @location 
			      AND part_no = @part_no 
			      AND line_no = @line_no 
			      AND lot_ser = @lot_ser
			      AND bin_no = @bin_no)
		BEGIN
			UPDATE tdc_soft_alloc_tbl
			   SET qty = qty + @mgt_qty
			 WHERE order_type = @order_type
			   AND order_no = @order_no 
			   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
		 	   AND location = @location 
			   AND part_no = @part_no 
			   AND line_no = @line_no 
			   AND lot_ser = @lot_ser
			   AND bin_no = @bin_no
		END
		ELSE
		BEGIN
			INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
				VALUES(@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no, @mgt_qty, @bin_no, @dest_bin, @trg_off, @order_type, @priority)
		END

		SELECT @tran_id = max(tran_id) 
		  FROM tdc_pick_queue
		 WHERE trans_type_no = @order_no
		   AND line_no = @line_no
		   AND part_no = @part_no
		   AND lot = @lot_ser
		   AND bin_no  = @bin_no

		IF (@qty <= 0) BREAK

		FETCH NEXT FROM cdock_mgt INTO @order_no, @order_ext, @cd_qty, @line_no, @tran_type, @tran_id
	END

	DEALLOCATE cdock_mgt

	SELECT @remain_qty = @qty

RETURN @tran_id
GO
GRANT EXECUTE ON  [dbo].[tdc_cross_dock_management] TO [public]
GO
