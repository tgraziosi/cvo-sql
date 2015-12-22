SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_open_carton_sp] 
@carton_no 	int,
@station_id	varchar(3),
@user_id	varchar(50),
@cube		int,
@err_msg	varchar(255) OUTPUT
AS

DECLARE @status    char(1),
	@order_No  int,
	@order_ext int

IF (SELECT COUNT(*) FROM tdc_stage_carton
	WHERE carton_no = @carton_no) > 0 
BEGIN
	SELECT @err_msg = 'Carton already freighted'
	RETURN -1
END

SELECT TOP 1 @status = status FROM tdc_carton_tx(NOLOCK) WHERE carton_no = @carton_no

IF (@status NOT IN ('C','F'))
BEGIN
	SELECT @err_msg = 'Carton is not closed'
	RETURN -2
END

IF EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl(NOLOCK)
	  WHERE carton_no = @carton_no)
BEGIN
	SELECT @err_msg = 'Carton has been assigned to a master pack'
	RETURN -3
END

BEGIN TRAN
	UPDATE tdc_carton_tx 
	   SET status = 'O',
	       carton_content_value = 0  
	 WHERE carton_no = @carton_no

	IF @@ERROR <> 0 
	BEGIN
		ROLLBACK TRAN
		RETURN -4
	END

	UPDATE tdc_carton_detail_tx 
	   	SET status = 'O', tx_date = getdate()
	 	WHERE carton_no = @carton_no

	IF @@ERROR <> 0 
	BEGIN
		ROLLBACK TRAN
		RETURN -5
	END

	UPDATE tdc_dist_group
	   	SET status = 'O'
	 	WHERE parent_serial_no = @carton_no

	IF @@ERROR <> 0 
	BEGIN
		ROLLBACK TRAN
		RETURN -6
	END

--        IF @Cube = 1
--	BEGIN
	         --  added on 8-13-01 by Trevor Emond for Analysis Services logging
--         	INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, tran_no, tran_ext)                     
--                SELECT @station_id, @user_id,  'VB', 'PPS', 'Open Carton', 1, @carton_no, order_no, order_ext
--		  FROM tdc_carton_tx (nolock)
--		 WHERE carton_no = @carton_no           
--        End

COMMIT TRAN
RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_open_carton_sp] TO [public]
GO
