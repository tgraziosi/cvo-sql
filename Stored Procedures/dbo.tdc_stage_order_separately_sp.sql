SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_stage_order_separately_sp]
@order_type CHAR(1),
@OrderNo  INT,
@OrderExt INT,
@UserID	  VARCHAR(50),
@ErrMsg	  VARCHAR(255) OUTPUT
AS 

DECLARE @NewStage VARCHAR(50)

IF NOT EXISTS(SELECT * FROM tdc_order WHERE order_no = @OrderNo)
BEGIN
	SELECT @ErrMsg = 'Invalid order number'
	RETURN -1
END

IF NOT EXISTS(SELECT * FROM tdc_order WHERE order_no = @OrderNo
				      AND order_ext = @OrderExt)
BEGIN
	SELECT @ErrMsg = 'Invalid order extention'
	RETURN -1
END

--Cannot stage cartons that have tdc_ship_flag
IF NOT EXISTS(SELECT * FROM tdc_stage_carton WHERE tdc_ship_flag = 'N' 
	  AND carton_no IN (SELECT carton_no FROM tdc_carton_tx
			    WHERE order_no = @OrderNo 
			    AND order_ext = @OrderExt	
			    AND order_type = @order_type))
BEGIN	
	SELECT @ErrMsg = 'All cartons from this order have already been shipped'
	RETURN -1
END

BEGIN TRAN
EXEC tdc_increment_stage_sp @NewStage OUTPUT


--update records in tdc_stage_carton with new stage number

UPDATE tdc_stage_carton 
SET stage_no = @NewStage
WHERE tdc_ship_flag = 'N' AND tdc_stage_carton.carton_no IN 
		(SELECT distinct carton_no 
		 FROM tdc_carton_tx 
		 WHERE order_no = @OrderNo
		 AND order_ext = @OrderExt
		 AND order_type = @order_type)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRAN
	SELECT @ErrMsg = 'Critical error during stage'
	RETURN -1
END

--Log the transaction
INSERT INTO tdc_log (trans_source, tran_date, trans, tran_no, tran_ext, data, UserID) 
VALUES ('VB', GETDATE(),'StageOrderSeparately', CAST(@OrderNo AS VARCHAR(50)) ,
	 CAST(@OrderExt AS VARCHAR(50)), 'Stage: ' + @NewStage, @UserID)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRAN
	SELECT @ErrMsg = 'Critical error during stage'
	RETURN -1
END

--Increment the stage so that this stage is not used
EXEC tdc_increment_stage_sp @NewStage OUTPUT
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRAN
	SELECT @ErrMsg = 'Critical error during stage'
	RETURN -1
END

COMMIT TRAN

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_stage_order_separately_sp] TO [public]
GO
