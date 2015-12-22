SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_xfer_after_save_sp]	@xfer_no INT
AS
BEGIN
	DECLARE @retval INT,
			@status CHAR(1),
			@user_id VARCHAR(50)
			
	SET @user_id = SUSER_SNAME()

	-- Get transer details
	SELECT
		@status = [status]
	FROM
		dbo.xfers_all (NOLOCK)
	WHERE
		xfer_no = @xfer_no

	-- If voided then unallocate
	IF @status = 'V'
	BEGIN
		EXEC cvo_plw_xfer_unallocate_sp @xfer_no, @user_id
		RETURN
	END

	IF @status > 'N'
	BEGIN
		RETURN
	END

	-- Call auto allocation code
	EXEC @retval = dbo.cvo_auto_allocate_xfer_sp @xfer_no 

END
GO
GRANT EXECUTE ON  [dbo].[cvo_xfer_after_save_sp] TO [public]
GO
