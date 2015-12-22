SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_dist_ship_verify_order_sp] 
AS


DECLARE @order_no int, 
	@ext int,
	@err int,
	@who varchar(50),
	@err_msg varchar(255)

SELECT @err = 0, @err_msg = null

IF NOT EXISTS (SELECT * FROM #tdc_dist_ship_order)
BEGIN
	-- No data being processing
	RETURN -106
END

SELECT @who = who FROM #temp_who

SELECT @order_no = order_no, @ext = ext
	FROM #tdc_dist_ship_order 
		WHERE row_id = 1

CREATE TABLE #adm_ship_order (
	order_no int not null,
	ext int not null,
	err_msg varchar(255) null,
	row_id int identity not null
)

INSERT INTO #adm_ship_order (order_no,ext,err_msg) VALUES (@order_no, @ext, null)

BEGIN TRAN	

	EXEC @err = tdc_adm_ship_order 0

	IF @err < 0
	BEGIN
		SELECT @err_msg = err_msg FROM #adm_ship_order WHERE err_msg IS NOT NULL

		-- if stored procedure tdc_ship_order rollback a transaction
		-- I think @@TRANCOUNT may become zero
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN

		UPDATE #tdc_dist_ship_order SET err_msg = @err_msg
		DROP TABLE #adm_ship_order
		RETURN -105
	END

	UPDATE tdc_serial_no_track
		SET last_trans = 'STDOSHVF', date_time = getdate(), [User_id] = @who
			WHERE last_tx_control_no = @order_no AND last_control_type = 'S'

	INSERT INTO tdc_bkp_dist_item_pick (method,order_no,order_ext,line_no,part_no,lot_ser,bin_no,
										quantity,child_serial_no,[function],type,status,bkp_status,	bkp_date)
	 	SELECT method,order_no,	order_ext,line_no,part_no,lot_ser,bin_no,quantity,child_serial_no,[function],type,
			status, 'C', GETDATE() FROM tdc_dist_item_pick (nolock) 
			WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S'
	
	DELETE FROM tdc_dist_item_pick WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S'

	INSERT INTO tdc_bkp_dist_item_list (order_no,order_ext,line_no,part_no,quantity,shipped,[function],bkp_status,bkp_date)
		 SELECT order_no,order_ext,line_no,part_no,quantity,shipped,[function], 'C', GETDATE() 
			FROM tdc_dist_item_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S'
	
	DELETE FROM tdc_dist_item_list WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S'
	
	IF EXISTS (SELECT * FROM tdc_ord_list_kit WHERE order_no = @order_no AND order_ext = @ext)
	BEGIN
		INSERT INTO tdc_bkp_ord_list_kit (order_no,order_ext,part_no,line_no,ordered,picked,location,
										  kit_part_no,sub_kit_part_no,qty_per_kit,kit_picked,bkp_status,bkp_date)
			SELECT order_no,order_ext,part_no,line_no,ordered,picked,location,kit_part_no,sub_kit_part_no,
				   qty_per_kit,kit_picked, 'C', GETDATE() 
				FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext
	
		DELETE FROM tdc_ord_list_kit WHERE order_no = @order_no AND order_ext = @ext
	END


DROP TABLE #adm_ship_order

COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_dist_ship_verify_order_sp] TO [public]
GO
