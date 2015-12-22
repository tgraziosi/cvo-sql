SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_mp_manifest_response_sp]
	@is_freighting	char(1), --FREIGHT/UNFREIGHT FLAG
	@pack_no	int,
	@stage_no	varchar(20),
	@user_id	varchar(50),
	@err_msg	varchar(255) OUTPUT

AS
DECLARE @carton_no int,
	@ret 	   int

DECLARE mp_cartons_cur CURSOR FOR
	SELECT carton_no 
	  FROM tdc_master_pack_ctn_tbl (NOLOCK)
	 WHERE pack_no = @pack_no

OPEN mp_cartons_cur
FETCH NEXT FROM mp_cartons_cur INTO @carton_no

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC @ret = tdc_pps_manifest_response_sp @is_freighting, @carton_no, @stage_no, @user_id, @err_msg OUTPUT

	IF @ret < 0 
	BEGIN
		CLOSE mp_cartons_cur
		DEALLOCATE mp_cartons_cur
		RETURN @ret
	END
	
	FETCH NEXT FROM mp_cartons_cur INTO @carton_no
END

CLOSE mp_cartons_cur
DEALLOCATE mp_cartons_cur

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_mp_manifest_response_sp] TO [public]
GO
