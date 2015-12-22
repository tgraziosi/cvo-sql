SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_master_pack_stl_remove_cartons_sp]
(
	@CARTON_NO	INT
)
--SEE IF THE CARTON ENTERED IS PART OF A MASTER PACK
AS

DECLARE	
	@MP		INT,		
	@ORDER_NO	INT,
	@ORDER_EXT	INT

IF EXISTS(SELECT *
	    FROM tdc_master_pack_ctn_tbl del (nolock), tdc_master_pack_tbl hdr (nolock) 
	   WHERE hdr.pack_no = del.pack_no
	     AND hdr.status = 'S'  
	     AND del.carton_no = @CARTON_NO) 
BEGIN
	BEGIN TRAN

  	SELECT @MP = min(pack_no) FROM tdc_master_pack_ctn_tbl WHERE carton_no = @CARTON_NO

	DECLARE master_cursor CURSOR FOR 
		SELECT order_no, order_ext, carton_no
		  FROM tdc_carton_tx 
		 WHERE carton_no IN (SELECT carton_no FROM tdc_master_pack_ctn_tbl (NOLOCK) WHERE pack_no = @MP)

	OPEN master_cursor
	FETCH NEXT FROM master_cursor INTO @ORDER_NO, @ORDER_EXT, @CARTON_NO
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE tdc_carton_tx 
		   SET stlbin_no = NULL 
		 WHERE order_no = @ORDER_NO 
		   AND order_ext = @ORDER_EXT 
		   AND carton_no = @CARTON_NO
		
		IF @@ERROR <> 0
		BEGIN
			CLOSE master_cursor
			DEALLOCATE master_cursor
			ROLLBACK TRAN
			RETURN -101
		END

		FETCH NEXT FROM master_cursor INTO @ORDER_NO, @ORDER_EXT, @CARTON_NO
	END

	CLOSE master_cursor
	DEALLOCATE master_cursor

	COMMIT TRAN
END
GO
GRANT EXECUTE ON  [dbo].[tdc_master_pack_stl_remove_cartons_sp] TO [public]
GO
