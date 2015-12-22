SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_save_bin2bin_tran] (
@tran_id int, 
@location varchar(10), 
@part_no varchar(30), 
@lot varchar(25),
@from_bin varchar(12),
@to_bin varchar(12),
@qty_to_process int,
@assign_type varchar(1),
@assign_user_or_group varchar(25),
@priority int,
@user_id varchar(50))
AS
/**************************************************************************
tdc_save_bin2bin_tran - This stored procedure is used to update existing
transactions or save new ones.

Rules:If tran_id is a positive integer, the save request is considered an 
update to an existing transaction. Otherwise, the information is used to 
create a new transaction, and a new tran_id is generated. 

For an update, if the priority was changed, a new sequence number is obtained
for the transaction in the new priority (of course, this puts the transaction
at the end on the list in the new priority.)

Return value:
     0 - Success
    -1 - Failed

12/2/1999    Initial        Samuel Eniojukan
***************************************************************************/
SET NOCOUNT ON

DECLARE @qty_avail_in_lbs int
DECLARE @qty_held_on_queue int
DECLARE @new_seq_num int
DECLARE @AssignUser varchar(25)
DECLARE @AssignGroup varchar(25)
DECLARE @msg varchar(255)
DECLARE @language varchar(10)

SELECT @AssignUser = NULL
SELECT @AssignGroup = NULL
SELECT @new_seq_num = 0

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @user_id), 'us_english')
SELECT @priority = value_str FROM tdc_config where [function] = 'Pick_Q_Priority'
IF @priority IN ('', '0')
	SELECT @priority = '5'
IF @tran_id > 0 
  BEGIN
    IF NOT EXISTS(select null from tdc_pick_queue (NOLOCK) where tran_id = @tran_id)
      BEGIN
	-- Invalid Tran_id ''%d''.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -101 AND language = @language
        raiserror(@msg, 16, -1, @tran_id)
        return -1
      END

    IF NOT EXISTS(select null from locations (NOLOCK) where location = @location)
      BEGIN
	-- Invalid Location ''%s''.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -102 AND language = @language
        raiserror(@msg, 16, -1, @location)
        return -1
      END

    IF NOT EXISTS(select null from lot_bin_stock (NOLOCK) 
                     WHERE location = @location AND part_no = @part_no)
      BEGIN
	-- Part ''%s'' not found in location ''%s''.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -103 AND language = @language
        raiserror(@msg, 16, -1, @part_no, @location)
        return -1
      END

    IF NOT EXISTS(SELECT null FROM lot_bin_stock (NOLOCK) WHERE location = @location 
                AND part_no = @part_no AND lot_ser = @lot)
      BEGIN
	-- Part number ''%s'' not found in lot ''%s''.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -104 AND language = @language
        raiserror(@msg, 16, -1, @part_no, @lot)
        return -1
      END

    IF @qty_to_process <= 0
      BEGIN
	-- Quantity to process is invalid
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -105 AND language = @language
        raiserror(@msg, 16, -1)
        return -1
      END

    exec @qty_avail_in_lbs = tdc_inventory_update @location, @part_no, 
                            @lot, @from_bin, -1, @qty_to_process, -1, 0

    SELECT @qty_held_on_queue = isnull(sum(qty_to_process),0) from tdc_pick_queue (NOLOCK)
                WHERE trans = 'MGTB2B' AND location = @location 
                AND part_no = @part_no AND lot = @lot

    IF (@qty_avail_in_lbs - @qty_held_on_queue) < @qty_to_process
      BEGIN
        -- 'Requested quantity of Part ''%s'' is not available in bin ''%s''. ' +
        -- '[Info: Quantity in Stock - %d, Quantity pending transfer on queue - %d, Quantity requested - %d]'
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -106 AND language = @language
        raiserror(@msg, 16, -1, @part_no, @from_bin,@qty_avail_in_lbs, @qty_held_on_queue, @qty_to_process)
        return -1
      END

    IF NOT EXISTS(select null from lot_bin_stock (NOLOCK) 
                     WHERE location = @location AND bin_no = @to_bin)
      BEGIN
	-- Destination bin ''%s'' not found in location ''%s''
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -107 AND language = @language 
        raiserror(@msg, 16, -1, @to_bin, @location)
        return -1
      END

    IF @assign_type = 'G'
      BEGIN
        IF NOT EXISTS(SELECT null FROM tdc_group (NOLOCK) WHERE Group_Id = @assign_user_or_group)
          BEGIN
	    -- Invalid Group ''%s''
	    SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -108 AND language = @language 
            raiserror(@msg, 16, -1, @assign_user_or_group)
            return -1
          END
        SELECT @AssignGroup = @assign_user_or_group
      END

    IF @assign_type = 'U'
      BEGIN
        IF NOT EXISTS(SELECT null FROM tdc_sec (NOLOCK) WHERE userid = @assign_user_or_group)
          BEGIN
	    -- Invalid User ''%s''
	    SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -109 AND language = @language 
            raiserror(@msg, 16, -1, @assign_user_or_group)
            return -1
          END
        SELECT @AssignUser = @assign_user_or_group
      END
    
    IF NOT EXISTS(SELECT null FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id and priority = @priority)
      BEGIN   
        exec @new_seq_num = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority
      END
    ELSE
      SELECT @new_seq_num = seq_no FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id

    UPDATE tdc_pick_queue SET location = @location, part_no = @part_no, lot = @lot,
        bin_no = @from_bin, next_op = @to_bin, qty_to_process = @qty_to_process,
        assign_group = @AssignGroup, assign_user_id = @AssignUser, priority = @priority,
        seq_no = @new_seq_num, user_id = @user_id, date_time = CURRENT_TIMESTAMP
    WHERE tran_id = @tran_id

   END
ELSE
  BEGIN
    IF NOT EXISTS(select null from locations (NOLOCK) where location = @location)
      BEGIN
	-- Invalid Location ''%s''
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -102 AND language = @language 
        raiserror(@msg, 16, -1, @location)
        return -1
      END

    IF NOT EXISTS(select null from lot_bin_stock (NOLOCK) 
                     WHERE location = @location AND part_no = @part_no)
      BEGIN
	-- Part ''%s'' not found in location ''%s''
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -103 AND language = @language 
        raiserror(@msg, 16, -1, @part_no, @location)
        return -1
      END

    IF NOT EXISTS(SELECT null FROM lot_bin_stock (NOLOCK) WHERE location = @location 
                AND part_no = @part_no AND lot_ser = @lot)
      BEGIN
	-- Part ''%s'' not found in lot ''%s''
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -104 AND language = @language 
        raiserror(@msg, 16, -1, @part_no, @lot)
        return -1
      END

    IF @qty_to_process <= 0
      BEGIN
	-- Quantity to process is invalid
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -105 AND language = @language 
        raiserror(@msg, 16, -1)
        return -1
      END

    exec @qty_avail_in_lbs = tdc_inventory_update @location, @part_no, 
                            @lot, @from_bin, -1, @qty_to_process, -1, 0

    SELECT @qty_held_on_queue = isnull(sum(qty_to_process),0) from tdc_pick_queue (NOLOCK)
                WHERE trans = 'MGTB2B' AND location = @location 
                AND part_no = @part_no AND lot = @lot

    IF (@qty_avail_in_lbs - @qty_held_on_queue) < @qty_to_process
      BEGIN
        -- 'Requested quantity of Part ''%s'' is not available in bin ''%s''. ' +
        -- '[Info: Quantity in Stock - %d, Quantity pending transfer on queue - %d, Quantity requested - %d]'
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -106 AND language = @language 
        raiserror(@msg, 16, -1, @part_no, @from_bin,@qty_avail_in_lbs, @qty_held_on_queue, @qty_to_process)
        return -1
      END

    IF NOT EXISTS(select null from lot_bin_stock (NOLOCK) 
                     WHERE location = @location AND bin_no = @to_bin)
      BEGIN
	-- Destination bin ''%s'' not found in location ''%s''
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -107 AND language = @language 
        raiserror(@msg, 16, -1, @to_bin, @location)
        return -1
      END

    IF @assign_type = 'G'
      BEGIN
        IF NOT EXISTS(SELECT null FROM tdc_group (NOLOCK) WHERE Group_Id = @assign_user_or_group)
          BEGIN
	    -- Invalid Group ''%s''
	    SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -108 AND language = @language 
            raiserror(@msg, 16, -1, @assign_user_or_group)
            return -1
          END
        SELECT @AssignGroup = @assign_user_or_group
      END

    IF @assign_type = 'U'
      BEGIN
        IF NOT EXISTS(SELECT null FROM tdc_sec (NOLOCK) WHERE userid = @assign_user_or_group)
          BEGIN
	    -- Invalid User ''%s''
	    SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_save_bin2bin_tran' AND err_no = -109 AND language = @language 
            raiserror(@msg, 16, -1, @assign_user_or_group)
            return -1
          END
        SELECT @AssignUser = @assign_user_or_group
      END
    
    exec @new_seq_num = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority

    INSERT INTO tdc_pick_queue (location, part_no, lot,
        bin_no, next_op, qty_to_process,
        assign_group, assign_user_id , priority,
        seq_no, user_id, date_time,
        tx_control, tx_lock, trans_source, trans)
    Values(@location,@part_no,@lot,
        @from_bin, @to_bin, @qty_to_process,
        @AssignGroup, @AssignUser, @priority,
        @new_seq_num, @user_id, CURRENT_TIMESTAMP,
        'M', 'H', 'VB', 'MGTB2B')
  END
GO
GRANT EXECUTE ON  [dbo].[tdc_save_bin2bin_tran] TO [public]
GO
