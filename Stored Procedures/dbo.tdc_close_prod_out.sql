SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_close_prod_out] (
	@location	varchar (10),
	@part_no	varchar (30),
	@prod_no	int,
	@prod_ext       int,
	@userid		varchar(50),
	@lb_tracked	char(1)
	) 
AS

SET NOCOUNT ON

DECLARE @line_no as int
DECLARE @bin_no as varchar(12)
DECLARE @lot as varchar(25)
DECLARE @status as char(1)
SET @status = 'S'

--if it is qc required item for finished goods
IF EXISTS (SELECT 1 FROM inv_master WHERE part_no = @part_no AND qc_flag = 'Y')
BEGIN
	SET @status = 'R'

	UPDATE lot_bin_prod
	   SET date_tran = getdate()
	 WHERE tran_no = @prod_no
	   AND tran_ext = @prod_ext
	   AND part_no = @part_no
	   AND line_no < 0
END

BEGIN
	-- If the end product is an lb_tracked, need to update lot_bin_prod table
	IF @lb_tracked = 'Y' 
	BEGIN
		DECLARE LB_cursor CURSOR FOR 
-- 			SELECT bin_no, lot_ser, line_no 
-- 			  FROM lot_bin_prod 
-- 			 WHERE tran_no = @prod_no
-- 			   AND tran_ext = @prod_ext 
-- 			   AND location = @location
-- 			   AND part_no = @part_no

			SELECT bin_no, lot_ser, line_no
			  FROM lot_bin_prod
			 WHERE tran_no = @prod_no
			   AND tran_ext = @prod_ext 
			   AND direction > 0
			   AND line_no > 0

		OPEN LB_cursor
		FETCH NEXT FROM LB_cursor INTO @bin_no, @lot, @line_no

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			UPDATE lot_bin_prod 
			   SET tran_code = @status, date_tran = getdate(), who = @userid
			 WHERE CURRENT OF LB_cursor

			FETCH NEXT FROM LB_cursor INTO @bin_no, @lot, @line_no
		END
		DEALLOCATE LB_cursor
	END
	
	-- Update prod_list.  Note: have to update line-by-line
	DECLARE line_cursor CURSOR FOR 
		SELECT line_no 
		  FROM prod_list
		 WHERE prod_no = @prod_no 
		   AND prod_ext = @prod_ext
-- 		   AND location = @location
-- 		   AND part_no = @part_no 
		   AND direction < 0

	OPEN line_cursor
	FETCH NEXT FROM line_cursor INTO @line_no

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		UPDATE prod_list 
		   SET status = @status 
		 WHERE CURRENT OF line_cursor

		FETCH NEXT FROM line_cursor INTO @line_no
	END
	DEALLOCATE line_cursor

	UPDATE prod_list 
	   SET status = 'S', last_tran_date = getdate()
	 WHERE prod_no = @prod_no 
	   AND prod_ext = @prod_ext
	   AND direction > 0

	-- Update produce table
	UPDATE produce 
	   SET who_entered = @userid, status = @status 
	 WHERE prod_no = @prod_no
	   AND prod_ext = @prod_ext
	   AND status = 'Q'

	-- For WO Batch Tracked delete records from tdc_wo_batch_track AND tdc_next_batch_no
	-- that wasn't used for produce
	IF EXISTS (SELECT * FROM tdc_wo_batch_track WHERE prod_no = @prod_no AND prod_ext = @prod_ext AND batch_status in ('X', 'N'))
	BEGIN
		DELETE FROM tdc_next_batch_no 
		  FROM tdc_next_batch_no n, tdc_wo_batch_track w
		 WHERE n.batch_no = w.output_lot 
		   AND w.prod_no = @prod_no 
		   AND w.prod_ext = @prod_ext 
		   AND w.batch_status in ('X', 'N')
		
		DELETE FROM tdc_wo_batch_track 
		 WHERE prod_no = @prod_no 
		   AND prod_ext = @prod_ext 
		   AND batch_status in ('X', 'N')
	END

	UPDATE tdc_wo_batch_track 
	   SET batch_status = 'C', date_time = getdate() 
	 WHERE prod_no = @prod_no

	DELETE FROM tdc_wo_pick WHERE prod_no = @prod_no AND prod_ext = @prod_ext AND (pick_qty - used_qty) = 0
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_close_prod_out] TO [public]
GO
