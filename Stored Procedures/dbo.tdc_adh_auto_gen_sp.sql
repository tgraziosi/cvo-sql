SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_adh_auto_gen_sp]
	@rec_no		int,
	@part_no	varchar(30), 
	@location	varchar(10), 
	@lot		varchar(25), 
	@bin		varchar(12), 
	@userid		varchar(50),
	@qty		decimal(20,8)
AS

DECLARE @serial_no	varchar(40), 
	@serial_raw	varchar(40)

	--Get the adhoc rec no
	IF ISNULL(@rec_no, 0) = 0  
	BEGIN
		SELECT @rec_no = ISNULL(last_no, 0) 
		  FROM next_rec_no (NOLOCK) 
	
	        SELECT @rec_no = ISNULL(@rec_no, 0) + 1
	
	        UPDATE next_rec_no
		   SET last_no = @rec_no
		
		IF @@ERROR <> 0 ROLLBACK TRAN
	END


	TRUNCATE TABLE #serial_no

	EXEC tdc_get_next_sn_sp @part_no, @qty, @location

	TRUNCATE TABLE #temp_serial_numbers

	INSERT INTO #temp_serial_numbers (serial_no) 
	SELECT serial_no 
	  FROM #serial_no
		
	EXEC tdc_adh_update_serial_track_sp @rec_no, @part_no, @location, @lot, @bin, @userid, 1


GO
GRANT EXECUTE ON  [dbo].[tdc_adh_auto_gen_sp] TO [public]
GO
