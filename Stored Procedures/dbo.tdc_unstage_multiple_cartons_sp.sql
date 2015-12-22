SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_unstage_multiple_cartons_sp] 
	@user_id	varchar(50),
	@cube_reg	int, 
	@err_msg	varchar(255) OUTPUT
AS

DECLARE @order_no	int,
	@order_ext	int,
	@carton_no	int,
	@ret		int,
	@pack_no	int

DECLARE tdc_unstage_cur 
	CURSOR FOR 
		SELECT a.carton_no 
		  FROM #temp_ship_confirm_display_tbl a,
		       tdc_stage_carton b(NOLOCK)
		 WHERE a.carton_no = b.carton_no
		   AND b.tdc_ship_flag = 'N'
		   AND a.master_pack = 'N'
		 UNION
		SELECT DISTINCT a.pack_no
		  FROM tdc_master_pack_ctn_tbl a(NOLOCK),
		       #temp_ship_confirm_display_tbl b,
		       tdc_stage_carton c(NOLOCK)
		 WHERE a.pack_no = b.carton_no
		   AND a.carton_no = c.carton_no
		   AND b.master_pack = 'Y'
		   AND c.tdc_ship_flag = 'N'

OPEN tdc_unstage_cur

FETCH NEXT FROM tdc_unstage_cur INTO @carton_no
WHILE(@@FETCH_STATUS = 0)
BEGIN
	--SCR37080 by Jim on 5/9/07
	EXEC @ret = tdc_unstage_carton_or_mp_sp @carton_no, '999', @user_id, @cube_reg, @err_msg OUTPUT
	IF @ret < 1
	BEGIN 
		RETURN -1
	END	
	
	--Log the transaction
	INSERT INTO tdc_log (trans_source, tran_date, trans, tran_no, tran_ext, data, UserID) 
	SELECT 'VB', GETDATE(),'UnStageCarton', CAST(order_no AS VARCHAR(50)), 
		CAST(order_ext AS VARCHAR(50)) ,
		'CartonNo = ' + CAST(@carton_no AS VARCHAR(50)), @user_id 
		FROM tdc_carton_tx (NOLOCK)
		WHERE carton_no = @carton_no


	IF @@ERROR <> 0
	BEGIN
		SELECT @err_msg = 'Critical error logging the transaction'
		RETURN -1
	END

	FETCH NEXT FROM tdc_unstage_cur INTO @carton_no
END

CLOSE tdc_unstage_cur
DEALLOCATE tdc_unstage_cur


RETURN 1

GO
GRANT EXECUTE ON  [dbo].[tdc_unstage_multiple_cartons_sp] TO [public]
GO
