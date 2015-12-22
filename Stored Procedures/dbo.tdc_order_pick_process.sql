SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.tdc_order_pick_process    Script Date: 5/28/99 9:33:43 AM ******/

/****** Object:  Stored Procedure dbo.tdc_order_pick_process    Script Date: 5/4/99 4:59:12 PM ******/
CREATE PROC [dbo].[tdc_order_pick_process]  	(@tran_no int, @tran_ext int, @tran_line int, 
					@part varchar(30), @qty decimal(20,8), @entry_point varchar(20))
AS

DECLARE @msg varchar(255),
	@err int,
	@Operation_type varchar(10),
	@priority int,
	@seq_no int,
	@location varchar(10),
	@tx_control varchar(10),
	@tx_lock char(1),
	@language varchar(10)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

--RAISERROR ('Got here!.',16, 1)

SELECT @err = 0
if @entry_point = 'Pick_Select'
	goto Pick_Select
if @entry_point = 'Pick_Filter'
	goto Pick_Filter
if @entry_point = 'Prioritize'
	goto Prioritize
if @entry_point = 'Fine_Tune'
	goto Fine_Tune
if @entry_point = 'Bin_Assign'
	goto Bin_Assign
if @entry_point = 'Pick_List_Print'
	goto Pick_List_Print
if @entry_point = 'Pick_queue'
	goto Pick_Queue
else
begin
	-- Invalid entry point %s.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -101 AND language = @language
	RAISERROR (@msg, 16, 1, @entry_point)
end

Pick_Select:
/* Section for Pick Select processing */
SELECT @Operation_type = 'bypass'
IF @Operation_type IN ('manual','auto','bypass')
  BEGIN
  IF @Operation_type = 'manual'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'auto'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'bypass'
    BEGIN
	SELECT @err = 0
    END
  END
ELSE
  BEGIN
	-- Operation type %s does not exist for Pick_Select.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -102 AND language = @language
	RAISERROR (@msg, 16, 1, @Operation_type)
	RETURN
  END

Pick_Filter:
/* Section for Pick Filter processing */
SELECT @Operation_type = 'bypass'
IF @Operation_type IN ('manual','auto','bypass')
  BEGIN
  IF @Operation_type = 'manual'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'auto'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'bypass'
    BEGIN
	SELECT @err = 0
    END
  END
ELSE
  BEGIN
	-- Operation type %s does not exist for Pick_Filter.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -103 AND language = @language
	RAISERROR (@msg, 16, 1, @Operation_type)
	RETURN
  END

Prioritize:

/* Section for Prioritize processing */
SELECT @Operation_type = 'bypass'
IF @Operation_type IN ('manual','auto','bypass')
  BEGIN
  IF @Operation_type = 'manual'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'auto'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'bypass'
    BEGIN
	SELECT @err = 0
    END
  END
ELSE
  BEGIN
	-- Operation type %s does not exist for Prioritize.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -104 AND language = @language
	RAISERROR (@msg, 16, 1, @Operation_type)
	RETURN
  END

Fine_Tune:
/* Section for Fine_Tune processing */
SELECT @Operation_type = 'bypass'
IF @Operation_type IN ('manual','auto','bypass')
  BEGIN
  IF @Operation_type = 'manual'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'auto'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'bypass'
    BEGIN
	SELECT @err = 0
    END
  END
ELSE
  BEGIN
	-- Operation type %s does not exist for Fine_Tune.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -105 AND language = @language
	RAISERROR (@msg, 16, 1, @Operation_type)
	RETURN
  END

Bin_Assign:
/* Section for Bin_Assign processing */
SELECT @Operation_type = 'bypass'
IF @Operation_type IN ('manual','auto','bypass')
  BEGIN
  IF @Operation_type = 'manual'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'auto'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'bypass'
    BEGIN
	SELECT @err = 0
    END
  END
ELSE
  BEGIN
	-- Operation type %s does not exist for Bin_Assign.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -106 AND language = @language
	RAISERROR (@msg, 16, 1, @Operation_type)
	RETURN
  END

Pick_List_Print:
/* Section for Pick_List_Print processing */
SELECT @Operation_type = 'bypass'
IF @Operation_type IN ('manual','auto','bypass')
  BEGIN
  IF @Operation_type = 'manual'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'auto'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'bypass'
    BEGIN
	SELECT @err = 0
    END
  END
ELSE
  BEGIN
	-- Operation type %s does not exist for Pick_List_Print.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -107 AND language = @language
	RAISERROR (@msg, 16, 1, @Operation_type)
	RETURN
  END

Pick_Queue:
/* Section for dropping line item into the pick queue */
SELECT @Operation_type = 'manual'
IF @Operation_type IN ('manual','auto','mixed')
  BEGIN
  IF @Operation_type = 'manual'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'auto'
    BEGIN
	SELECT @err = 0
    END
  IF @Operation_type = 'mixed'
    BEGIN
	SELECT @priority = value_str FROM tdc_config where [function] = 'Pick_Q_Priority'
	IF @priority IN ('', '0')
		SELECT @priority = '5'

	EXEC @seq_no=tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority
	SELECT @location = location FROM ord_list WHERE order_no=@tran_no AND order_ext=@tran_ext
	SELECT @qty = ordered FROM ord_list WHERE order_no=@tran_no AND order_ext=@tran_ext
	SELECT @tx_control = 'X'
	SELECT @tx_lock = 'R'

	INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no, 
		location, trans_type_no, trans_type_ext, line_no, part_no, qty_to_process, 
		qty_processed, qty_short, tx_control, tx_lock)
	VALUES ('VB', 'PICK', @priority, @seq_no, @location, @tran_no, @tran_ext,
		@tran_line, @part, @qty, 0, 0, @tx_control, @tx_lock)

    END
  END
ELSE
  BEGIN
	-- Operation type %s does not exist for Pick_Queue_Control.
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_order_pick_process' AND err_no = -108 AND language = @language
	RAISERROR (@msg, 16, 1, @Operation_type)
	RETURN
  END

exit_sp:
RETURN @err

GO
GRANT EXECUTE ON  [dbo].[tdc_order_pick_process] TO [public]
GO
