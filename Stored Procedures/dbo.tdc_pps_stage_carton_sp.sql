SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_stage_carton_sp]
@CartonNo		INT,
@OrderNo		INT,
@OrderExt		INT,
@StageNo		VARCHAR(20),
@ErrMsg			VARCHAR(255) OUTPUT
AS

DECLARE @FreightType	VARCHAR(30), @language varchar(10)
DECLARE @Routing 	VARCHAR(255)
DECLARE @Cnt		INT


SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

BEGIN TRAN

SELECT @FreightType = freight_allow_type, @Routing = routing 
	FROM ORDERS (NOLOCK) 
	WHERE order_no = @OrderNo
	AND ext = @OrderExt

--Update Orders table
UPDATE tdc_carton_tx 
	SET status = 'S', date_shipped = NULL, 
	carrier_code = @Routing,
        charge_code = @FreightType
        WHERE carton_no = @CartonNo

IF @@ERROR <> 0 
BEGIN
	ROLLBACK TRAN
	-- 'Critical error during stage process'
	SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_stage_carton_sp' AND err_no = -101 AND language = @language 
	RETURN -1  
END
 
--Update Carton Detail status field.
UPDATE tdc_carton_detail_tx 
	SET status = 'S'
	WHERE carton_no = @CartonNo

IF @@ERROR <> 0 
BEGIN
	ROLLBACK TRAN
	-- 'Critical error during stage process'
	SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_stage_carton_sp' AND err_no = -101 AND language = @language 
	RETURN -2  
END

--Update the TDC Distribution Group Table.
UPDATE tdc_dist_group  
	SET status = 'S'  
	WHERE parent_serial_no = @CartonNo

IF @@ERROR <> 0 
BEGIN
	ROLLBACK TRAN
	-- 'Critical error during stage process'
	SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_stage_carton_sp' AND err_no = -101 AND language = @language 
	RETURN -3  
END
 
--Verify carton isn't already tied to an existing stage number.
--If not, then add carton to the active stage number.
IF EXISTS(SELECT * FROM tdc_stage_carton (NOLOCK)
	WHERE Carton_No = @CartonNo)

BEGIN	
	ROLLBACK TRAN
        -- 'Carton is already tied to a staging number'
	SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_stage_carton_sp' AND err_no = -102 AND language = @language 
   	RETURN -4
END
ELSE
BEGIN
   
        --create the carton/stage record.
        INSERT INTO tdc_stage_carton  
        (Carton_No, stage_no, tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date, stage_error, master_pack) 
        VALUES (@CartonNo, @StageNo, 'N', 'N', NULL, NULL, NULL, 'N') 
	IF @@ERROR <> 0 
	BEGIN
		ROLLBACK TRAN
		-- 'Critical error during stage process'
		SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_stage_carton_sp' AND err_no = -101 AND language = @language 
		RETURN -5  
	END
END  

COMMIT TRAN                  
RETURN 1

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_stage_carton_sp] TO [public]
GO
