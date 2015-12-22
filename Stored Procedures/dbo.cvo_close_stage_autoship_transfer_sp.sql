SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_close_stage_autoship_transfer_sp] (@xfer_no INT,  @user_id varchar(50), @station_id INT)
AS
BEGIN

	DECLARE @carton_no		INT,
			@status			CHAR(1),
			@ErrMsg			VARCHAR(255),
			@station_id_str	VARCHAR(3),
			@retval			INT,
			@weight			DECIMAL(20,8),
			@stage_no		CHAR(11)

	SET @station_id_str = CAST(@station_id AS VARCHAR(3))

	-- Get carton no
	SELECT 
		@carton_no = carton_no,
		@status = [status] 
	FROM 
		dbo.tdc_carton_tx  (NOLOCK)
	WHERE 
		order_no = @xfer_no
		AND order_type ='T'

	-- Does carton exist
	IF ISNULL(@carton_no,0) = 0
	BEGIN
		RETURN -1
	END

	-- Is it open
	IF ISNULL(@status,'') <> 'O'
	BEGIN
		RETURN -2
	END

	-- Is it part of a master pack
	IF EXISTS(SELECT 1 FROM tdc_master_pack_ctn_tbl(NOLOCK) WHERE carton_no = @carton_no)
	BEGIN
		RETURN -3
	END
	
	-- Check that tarnsfer is fully picked and packed
	IF EXISTS(SELECT 1 FROM dbo.tdc_pick_queue a (NOLOCK) join dbo.tdc_carton_detail_tx b (NOLOCK) ON a.trans_type_no = b.order_no AND a.trans_type_ext = b.order_ext WHERE b.carton_no = @carton_no AND a.trans = 'XFERPICK')
	BEGIN
		RETURN -4
	END

	IF EXISTS(SELECT 1 FROM dbo.tdc_dist_item_pick (NOLOCK) WHERE order_no = @xfer_no AND order_ext = 0 AND quantity > 0 AND [function] = 'T') 
	BEGIN
		RETURN -5
	END

	IF EXISTS(SELECT 1 FROM dbo.tdc_dist_item_list a (NOLOCK) JOIN tdc_soft_alloc_tbl b (NOLOCK) ON a.order_no = b.order_no and a.order_ext = b.order_ext WHERE a.order_no = @xfer_no AND a.order_ext = 0 AND a.shipped = 0 AND a.[function] = 'T') 
	BEGIN
		RETURN -6
	END

	-- Close carton
	EXEC @retval = tdc_close_carton_sp @carton_no, @station_id_str ,@user_id, 1, @ErrMsg OUTPUT
	IF @retval < 0
	BEGIN
		RETURN -7
	END
	
	-- Write log
	INSERT INTO tdc_log (
		tran_date, 
		trans, 
		UserID, 
		trans_source, 
		module, 
		data, 
		tran_no,
		tran_ext, 
		part_no, 
		lot_ser, 
		bin_no,
		quantity,
		location ) 
	SELECT 
		GETDATE(),  
		'Close Carton',  
		@user_id,
		'VB',
		'PPS',
		'Carton: ' + CAST(@carton_no AS VARCHAR(10)), 
		'', 
		'', 
		'', 
		'', 
		'', 
		'', 
		''

	-- Update carton weight
	SELECT 
		@weight = SUM(a.pack_qty * b.weight_ea)    
	FROM 
		dbo.tdc_carton_detail_tx a (NOLOCK)
	INNER JOIN
		dbo.inv_master b (NOLOCK)
	ON
		a.part_no = b.part_no
	WHERE 
		a.carton_no = @carton_no

	UPDATE 
		tdc_carton_tx          
	SET 
		weight = ISNULL(@weight,0) 
	WHERE 
		carton_no = @carton_no


	-- Stage carton
	SELECT @stage_no = 'AS-' + RIGHT('00000000' + CAST(@carton_no AS VARCHAR(10)),8)

	EXEC @retval = tdc_stage_carton_or_mp_sp @carton_no,@stage_no, 1,@station_id_str ,@user_id, @ErrMsg OUTPUT
	IF @retval < 0
	BEGIN
		RETURN -8
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_close_stage_autoship_transfer_sp] TO [public]
GO
