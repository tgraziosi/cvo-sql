SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_process_bin_quarantine_sp]
	@bin_no	  VARCHAR(12),
	@user_id  VARCHAR(50),
	@location VARCHAR(10),
	@err_msg  VARCHAR(255) OUTPUT

AS
DECLARE
	@original_usage_type_code	VARCHAR(10),
	@quarantined_by			VARCHAR(25),
	@quarantined_when		DATETIME,
	@status				CHAR(1),
	@is_allocated			INT,
	@language 			VARCHAR(10)
	
	SELECT @language = ISNULL(language, 'us_english') FROM tdc_sec (nolock) WHERE userid = @user_id
	--FIRST WE SEE IF THE BIN PASSED IN IS IN THE NEW TABLE: tdc_bin_quarantine
	IF EXISTS(SELECT * FROM tdc_bin_quarantine (NOLOCK) WHERE bin_no = @bin_no AND location = @location)
	BEGIN
		SELECT @original_usage_type_code = original_usage_type_code, 
		       @quarantined_by = quarantined_by,
		       @quarantined_when = quarantined_when
	 	FROM tdc_bin_quarantine
		WHERE bin_no = @bin_no AND location = @location
		--WE MUST DELETE THE RECORD FIRST, BECAUSE THE TRIGGER ON THE tdc_bin_master WON'T ALLOW US TO UPDATE THE STATUS
		--OF A BIN THAT IS IN THE tdc_bin_quarantine TABLE.
		--DELETE RECORD FROM tdc_bin_quarantine
		DELETE FROM tdc_bin_quarantine WHERE bin_no = @bin_no AND location = @location
		--UPDATE tdc_bin_master
		UPDATE tdc_bin_master SET usage_type_code = @original_usage_type_code WHERE bin_no = @bin_no AND location = @location
		SELECT @err_msg = @original_usage_type_code
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT * FROM tdc_bin_master (NOLOCK) WHERE bin_no = @bin_no AND location = @location)
		BEGIN
			SELECT @original_usage_type_code = usage_type_code, @status = status FROM tdc_bin_master WHERE bin_no = @bin_no AND location = @location
			IF @status <> 'A' 
			BEGIN
				--SELECT @err_msg = 'Bin status must be active.'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_QUARANTINE' AND err_no = 3 AND language = @language
				RETURN -3 --Bin status must be active.
			END

			IF @original_usage_type_code NOT IN ('OPEN', 'REPLENISH') 
			BEGIN
				--'Bin type must be either OPEN or REPLENISH to quarantine.'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_QUARANTINE' AND err_no = 2 AND language = @language
				RETURN -2 --Bin type must be either OPEN or REPLENISH to quarantine.
			END

			IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @bin_no AND location = @location)
			BEGIN 
				--'Bin cannot be quarantined, items are allocated.'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_QUARANTINE' AND err_no = 4 AND language = @language
				RETURN -4 --Bin cannot be quarantined, items are allocated.
			END

			IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE bin_no = @bin_no AND location = @location)
			BEGIN
				--'Bin cannot be quarantined, items are on the pick queue for this bin.'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_QUARANTINE' AND err_no = 5 AND language = @language
				RETURN -5 --Bin cannot be quarantined, items are on the pick queue for this bin.
			END

			IF EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK) WHERE next_op = @bin_no AND location = @location)
			BEGIN
				--'Bin cannot be quarantined, items are on the pick queue for this bin.'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_QUARANTINE' AND err_no = 7 AND language = @language 
				RETURN -7 --Bin cannot be quarantined, items are on the pick queue for this bin.
			END

			IF EXISTS(SELECT * FROM tdc_put_queue (NOLOCK) WHERE bin_no = @bin_no AND location = @location)
			BEGIN
				--'Bin cannot be quarantined, items are on the put queue for this bin.'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_QUARANTINE' AND err_no = 6 AND language = @language
				RETURN -6 --Bin cannot be quarantined, items are on the put queue for this bin.
			END

			SELECT @quarantined_by = @user_id, @quarantined_when = GETDATE()

			--INSERT RECORD INTO tdc_bin_quarantine
			INSERT INTO tdc_bin_quarantine (bin_no, location, original_usage_type_code, quarantined_by, quarantined_when)
				VALUES(@bin_no, @location, @original_usage_type_code, @quarantined_by, @quarantined_when)
			--UPDATE tdc_bin_master
			UPDATE tdc_bin_master SET usage_type_code = 'QUARANTINE' WHERE bin_no = @bin_no AND location = @location
			SELECT @err_msg = 'QUARANTINE'
		END
		ELSE
		BEGIN
		  --'Bin entered does not exist in bin master table.'
		  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_QUARANTINE' AND err_no = 1 AND language = @language
		  RETURN -1 --Bin entered does not exist in bin master table.
		END
	END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_process_bin_quarantine_sp] TO [public]
GO
