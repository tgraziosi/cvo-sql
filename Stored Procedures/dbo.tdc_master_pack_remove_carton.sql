SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_master_pack_remove_carton]
	@pack_no 	int,
	@carton_no 	int, 
	@user_id	varchar(50),
	@err_msg	varchar(255) OUTPUT 
AS

DECLARE @cust_code varchar(10)

	IF EXISTS(SELECT * FROM tdc_master_pack_tbl(NOLOCK)
		   WHERE pack_no = @pack_no
		     AND status != 'O')
	BEGIN
		SELECT @err_msg = 'Master Pack is not open'
		RETURN -1
	END	

	IF NOT EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl(NOLOCK) WHERE pack_no = @pack_no AND carton_no = @carton_no)
	BEGIN
		SELECT @err_msg = 'Invalid carton no'
		RETURN -2
	END	 
	
	DELETE FROM tdc_master_pack_ctn_tbl
	 WHERE pack_no = @pack_no
	   AND carton_no = @carton_no

	IF NOT EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl WHERE pack_no = @pack_no)
	BEGIN
		DELETE FROM tdc_master_pack_tbl
		 WHERE pack_no = @pack_no
	END
	ELSE
	BEGIN
		UPDATE tdc_master_pack_tbl 
		   SET modified_by = @user_id,
		       last_modified_date = GETDATE()
		 WHERE pack_no = @pack_no
	END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_master_pack_remove_carton] TO [public]
GO
