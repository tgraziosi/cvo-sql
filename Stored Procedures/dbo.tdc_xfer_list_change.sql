SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*======================================================================*/
/*  	This procedure is called by a trigger on the    		*/
/*      xfer_list table.  The procedure takes @tran_no, @tran_line, 	*/
/*	@part_no, @qty and inserts order information into 		*/
/*	the tdc_dist_item_list       					*/
/*======================================================================*/
-- v1.1 CT 08/11/2012 - Allow transfers to be autopicked via SQL job

CREATE PROC [dbo].[tdc_xfer_list_change] (
	@tran_no int, 
	@tran_line int, 
	@part varchar(30), 
	@qty decimal(20,8), 
	@stat varchar(10)
)
 
AS

DECLARE @ordered decimal(20,8), 
	@tdc_ordered decimal(20,8),
	@shipped decimal(20,8), 
	@tdc_shipped decimal(20,8),
	@tdc_part varchar(30),
	@status varchar(1),
	@tdc_loc varchar(10),
	@location varchar(10),
	@errmsg VARCHAR(255), 
	@language VARCHAR(20),
	@valid_picker SMALLINT -- v1.1

SET NOCOUNT ON

SELECT @errmsg = 'Error message not found'
/***********************************************************************************/

SELECT @language = @@language -- Get system language

SELECT 	@language = 
	CASE 
		WHEN @language = 'Español' THEN 'Spanish'
		ELSE 'us_english'
	END

-- START v1.1 - check for existence of #temp_who table
IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
BEGIN
	SET @valid_picker = 1
END
ELSE
BEGIN
	SET @valid_picker = 0
END
-- END v1.1

-- Insert condition
IF (@stat = 'XFERL_INS')
BEGIN
	IF NOT EXISTS( SELECT * FROM tdc_dist_item_list (nolock) WHERE order_no = @tran_no AND line_no = @tran_line AND [function] = 'T')
	BEGIN
		INSERT INTO tdc_dist_item_list
			SELECT xfer_no, 0, line_no, part_no, ordered * conv_factor, 0, 'T'
			FROM xfer_list (nolock)
			WHERE xfer_no = @tran_no AND line_no = @tran_line AND part_no = @part
	END

	RETURN 0
END

/*************************************************************************************/

-- Delete condition
IF( @stat = 'XFERL_DEL') 
BEGIN
	IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no = @tran_no AND order_ext = 0 AND order_type = 'T' AND line_no = @tran_line)
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK TRAN

		-- Error message: Must unallocate inventory in DSF before deleting item %s.
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'XLCHANGE' AND err_no = -101
		RAISERROR(@errmsg, 16, -1, @part)
		RETURN 0
	END

	DELETE FROM tdc_dist_item_list 
		WHERE order_no = @tran_no AND line_no = @tran_line AND part_no = @part AND [function] = 'T'
	RETURN 0
END

/************************************************************************************/

/************************************************************************************/
-- Update condition				
SELECT @ordered = ordered * conv_factor, @shipped = shipped * conv_factor, @status = status, @location = from_loc
	FROM xfer_list (nolock)
		WHERE xfer_no = @tran_no AND line_no = @tran_line

SELECT @tdc_ordered = quantity, @tdc_shipped = shipped, @tdc_part = part_no 
	FROM tdc_dist_item_list (nolock)
		WHERE order_no = @tran_no AND line_no = @tran_line AND [function] = 'T'
/************************************************************************************/

-- Update conditon
IF (@stat = 'XFERL_UPD')
BEGIN
	IF @ordered = 0
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK TRAN

		-- Message: Ordered quantity can not be zero
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'XLCHANGE' AND err_no = -102
		RAISERROR(@errmsg, 16, 1)
		RETURN 0
	END

	-- START v1.1
	IF(SYSTEM_USER <> 'tdcsql') AND @valid_picker = 0
	-- IF(SYSTEM_USER <> 'tdcsql')
	-- END v1.1
	BEGIN
		SELECT @tdc_loc = location 
		  FROM tdc_soft_alloc_tbl (nolock) 
		 WHERE order_no = @tran_no 
		   AND order_type = 'T'
		   AND line_no = @tran_line

		IF (@tdc_loc IS NOT NULL) AND (@tdc_loc <> @location)
		BEGIN
			IF @@TRANCOUNT > 0 ROLLBACK TRAN
				
			RAISERROR('Must unallocate inventory in DSF before changing location %s.', 16, -1, @tdc_loc)
			RETURN 0
		END

		IF (@tdc_shipped <> @shipped)
		BEGIN
			IF EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @tran_no AND [function] = 'T')
			BEGIN
				IF @@TRANCOUNT > 0 ROLLBACK TRAN

				-- Message: Order %d is controlled by eWarehouse system
				SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'XLCHANGE' AND err_no = -103
				RAISERROR(@errmsg, 16, 1, @tran_no)
				RETURN 0 
			END

			IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no = @tran_no AND order_type = 'T')
			OR EXISTS (SELECT * FROM tdc_pick_queue (nolock) WHERE trans_type_no = @tran_no AND trans = 'XFERPICK')
			BEGIN
				IF @@TRANCOUNT > 0 ROLLBACK TRAN

				-- Message: Order %d is controlled by eWarehouse system
			--	SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'XLCHANGE' AND err_no = -103
				RAISERROR('Order %d must be unallocated', 16, 1, @tran_no)
				RETURN 0 
			END
		END	

		UPDATE tdc_dist_item_list 	
		SET quantity = @ordered, part_no = @part  
		WHERE order_no = @tran_no AND line_no = @tran_line AND [function] = 'T'
	END
END	

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_xfer_list_change] TO [public]
GO
