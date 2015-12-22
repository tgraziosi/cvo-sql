SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_fedex_freight_unfreight_sp]
	@freighting		int,
	@carton_no		int,
	@stage_no		varchar(20),
	@user_id		varchar(255)
AS 

DECLARE @Response 	varchar(1000),
	@SendString	varchar(1000),
	@Pos 		INT,
	@Length		INT,
	@FreightType	varchar(255),
	@FreightAmt	DECIMAL,
	@Cnt		INT,
	@language	varchar(10),
	@order_no	int,
	@order_ext	int,
	@pack_no	int,
	@is_master_pack char(1)
	


--Get the response string from the temp table
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

IF EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl(NOLOCK)  WHERE carton_no = @carton_no)
BEGIN
	SELECT @is_master_pack = 'Y'
	
	SELECT @pack_no = pack_no FROM tdc_master_pack_ctn_tbl(NOLOCK) WHERE carton_no = @carton_no
END
ELSE
BEGIN
	SELECT @is_master_pack = 'N'
END

--Log the response
INSERT INTO tdc_log (tran_no, tran_ext, tran_date, data, trans, UserID) 
SELECT order_no, order_ext, GETDATE(), 'Carton = ' + CAST(@carton_no AS VARCHAR) + ', Data: FedEx', 'DataArrival', @user_id 
  FROM tdc_carton_tx (NOLOCK)
 WHERE carton_no = @carton_no

IF @@ERROR <> 0 RETURN -1
 

--If freighting carton
IF @freighting = 1
BEGIN
	IF @stage_no IS NOT NULL
	BEGIN
		--After closing the carton, set the status to 'S' for triggers
		UPDATE tdc_carton_tx SET status = 'S' WHERE carton_no = @carton_no
		IF @@ERROR <> 0 RETURN -2

			
		IF @is_master_pack = 'Y'
		BEGIN
			UPDATE tdc_master_pack_tbl SET status = 'S' WHERE pack_no = @pack_no
			IF @@ERROR <> 0 RETURN -3
		END	

		UPDATE tdc_carton_detail_tx SET status = 'S' WHERE carton_no = @carton_no
		IF @@ERROR <> 0 RETURN -4
		
		UPDATE tdc_dist_group SET status = 'S' WHERE parent_serial_no = @carton_no
		IF @@ERROR <> 0 RETURN -5
	
		--Assign stage number
		INSERT INTO tdc_stage_carton (carton_no, stage_no, tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date, master_pack)  
	        VALUES (@carton_no, @stage_no, 'N', 'N', NULL, NULL, @is_master_pack) 
	
		IF @@ERROR <> 0 RETURN -6
	
		IF NOT EXISTS(SELECT * FROM tdc_stage_numbers_tbl(NOLOCK) WHERE stage_no = @stage_no)
		BEGIN
			INSERT INTO tdc_stage_numbers_tbl(stage_no, active, creation_date)
			SELECT @stage_no, 'Y', GETDATE()
		END
		ELSE
		BEGIN
			UPDATE tdc_stage_numbers_tbl SET active = 'Y' WHERE stage_no = @stage_no
		END

		IF @@ERROR <> 0 RETURN -7
	END
	ELSE	-- Stage No is NULL
	BEGIN
		--After closing the carton, set the status to 'S' for triggers
		UPDATE tdc_carton_tx SET status = 'F' WHERE carton_no = @carton_no
		IF @@ERROR <> 0 RETURN -8
			

		UPDATE tdc_carton_detail_tx SET status = 'F' WHERE carton_no = @carton_no
		IF @@ERROR <> 0 RETURN -9
			
		UPDATE tdc_dist_group SET status = 'F' WHERE parent_serial_no = @carton_no
		IF @@ERROR <> 0 RETURN -10
	END                    
END
ELSE --Unfreighting
BEGIN
	UPDATE tdc_carton_tx  
	   SET cs_tx_no        = '', cs_tracking_no       = '', cs_zone       = '',  
               cs_oversize     = '', cs_call_tag_no       = '', cs_airbill_no = '',  
               cs_other        = 0,  cs_pickup_no         = '', cs_dim_weight = 0, cs_published_freight = 0, 
               cs_disc_freight = 0,  cs_estimated_freight = '', date_shipped   = getdate(), status = 'C' 
         WHERE carton_no = @carton_no

	IF @@ERROR <> 0 RETURN -11

	-- Unstage carton to closed status
        UPDATE tdc_carton_tx SET status = 'C' WHERE carton_no = @carton_no
	IF @@ERROR <> 0 RETURN -12

	IF @is_master_pack = 'Y'
	BEGIN
		UPDATE tdc_master_pack_tbl SET status = 'C' WHERE pack_no = @pack_no
		IF @@ERROR <> 0 RETURN -13
	END

	UPDATE tdc_carton_detail_tx  SET status = 'C' WHERE carton_no = @carton_no

	IF @@ERROR <> 0 RETURN -14
      
        UPDATE tdc_dist_group SET status = 'C' WHERE parent_serial_no = @carton_no
	IF @@ERROR <> 0 RETURN -15

        DELETE FROM tdc_stage_carton  WHERE carton_no = @carton_no
	IF @@ERROR <> 0 RETURN -16

	-- If master pack, and removing all the cartons for the master pack,
	-- remove the master pack record.
	IF @is_master_pack = 'Y'
	BEGIN
		IF NOT EXISTS(SELECT * FROM tdc_stage_carton(NOLOCK)
			       WHERE carton_no IN(SELECT carton_no FROM tdc_master_pack_ctn_tbl(NOLOCK) WHERE pack_no = @pack_no))
		BEGIN
			DELETE FROM tdc_stage_carton WHERE carton_no = @pack_no
			IF @@ERROR <> 0 RETURN -17
		END

		UPDATE tdc_master_pack_tbl SET status = 'O' WHERE pack_no = @pack_no
		IF @@ERROR <> 0 RETURN -18
	END
END

DECLARE cur CURSOR FOR
SELECT order_no, order_ext FROM tdc_carton_tx (NOLOCK) WHERE carton_no = @carton_no

OPEN cur
FETCH NEXT FROM cur INTO @order_no, @order_ext

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC tdc_upd_ord_tots @order_no, @order_ext 
	FETCH NEXT FROM cur INTO @order_no, @order_ext
END

CLOSE      cur
DEALLOCATE cur


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_fedex_freight_unfreight_sp] TO [public]
GO
