SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_cdock_save_sp]
AS

DECLARE
	@tran_type	varchar(15),
	@tran_no	int,
	@tran_ext	int,
	@location	varchar(10),
	@part_no	varchar(30),
	@line_no	int,
	@from_tran_no	varchar(16),
	@from_tran_ext	int,
	@from_tran_type	char(1),  
	@release_date	datetime,
	@qty		decimal(24, 8) 

DECLARE upd_cur CURSOR FOR 
	SELECT a.tran_type, a.tran_no, a.tran_ext, a.location, a.part_no, a.line_no, a.from_tran_no, a.from_tran_ext, a.from_tran_type, a.release_date, a.qty
	  FROM #tmp_cdock_mgt a, 
		#xdock_demand b
	WHERE a.tran_type = b.tran_type
	  AND a.tran_no = b.tran_no
  	  AND ISNULL(a.tran_ext, 0) = ISNULL(b.tran_ext, 0)
	  AND a.location = b.location
	  AND a.line_no = b.line_no
	  AND a.part_no = b.part_no

OPEN upd_cur
FETCH NEXT FROM upd_cur INTO @tran_type, @tran_no, @tran_ext, @location, @part_no, @line_no, @from_tran_no, @from_tran_ext, @from_tran_type, @release_date, @qty

WHILE @@FETCH_STATUS = 0
BEGIN
	IF EXISTS (SELECT * FROM tdc_cdock_mgt (NOLOCK)
		    WHERE tran_type = tran_type
		      AND tran_no = @tran_no
		      AND ISNULL(tran_ext, 0) = ISNULL(@tran_ext, 0)
		      AND location = @location
		      AND part_no = @part_no
		      AND line_no = @line_no
		      AND from_tran_no = @from_tran_no
		      AND ISNULL(from_tran_ext, 0) = ISNULL(@from_tran_ext, 0)
		      AND from_tran_type = @from_tran_type
		      AND DATEDIFF(DAY, release_date, @release_date) = 0)
	BEGIN
		UPDATE tdc_cdock_mgt
		   SET qty = @qty
	         WHERE tran_type = tran_type
	           AND tran_no = @tran_no
	           AND ISNULL(tran_ext, 0) = ISNULL(@tran_ext, 0)
	           AND location = @location
	           AND part_no = @part_no
	           AND line_no = @line_no
	           AND from_tran_no = @from_tran_no
	           AND ISNULL(from_tran_ext, 0) = ISNULL(@from_tran_ext, 0)
	           AND from_tran_type = @from_tran_type
	           AND DATEDIFF(DAY, release_date, @release_date) = 0

		DELETE FROM tdc_cdock_mgt		   
	         WHERE tran_type = tran_type
	           AND tran_no = @tran_no
	           AND ISNULL(tran_ext, 0) = ISNULL(@tran_ext, 0)
	           AND location = @location
	           AND part_no = @part_no
	           AND line_no = @line_no
	           AND from_tran_no = @from_tran_no
	           AND ISNULL(from_tran_ext, 0) = ISNULL(@from_tran_ext, 0)
	           AND from_tran_type = @from_tran_type
	           AND DATEDIFF(DAY, release_date, @release_date) = 0
		   AND qty <= 0
	END
	ELSE
	BEGIN
		INSERT INTO tdc_cdock_mgt (tran_type, tran_no, tran_ext, location, part_no, line_no, from_tran_no, from_tran_ext, from_tran_type, release_date, qty)
		VALUES (@tran_type, @tran_no, @tran_ext, @location, @part_no, @line_no, @from_tran_no, @from_tran_ext, @from_tran_type, @release_date, @qty)
	END


	FETCH NEXT FROM upd_cur INTO @tran_type, @tran_no, @tran_ext, @location, @part_no, @line_no, @from_tran_no, @from_tran_ext, @from_tran_type, @release_date, @qty
END
CLOSE upd_cur
DEALLOCATE upd_cur

GO
GRANT EXECUTE ON  [dbo].[tdc_cdock_save_sp] TO [public]
GO
