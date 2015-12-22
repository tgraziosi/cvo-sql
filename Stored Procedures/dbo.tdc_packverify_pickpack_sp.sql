SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[tdc_packverify_pickpack_sp] 
		@order_no 			int,
		@order_ext 			int,
		@carton_no			int,
		@line_no 			int, 
		@location 			varchar(10), 
		@part_no 			varchar(30), 
		@lot_ser 			varchar(25), 
		@bin_no 			varchar(12), 
		@qty 				decimal(24,8), 
		@carton_type    		varchar(10),
		@carton_class   		varchar(10),
		@user_id 			varchar(50),
		@station_id			int,
		@not_using_orig_allocation	char(1),
		@error_msg 			varchar(255) 	OUTPUT
AS 

DECLARE @return	int

BEGIN TRAN	
	-- Pick the part
	EXEC @return = tdc_packverify_pick_sp @order_no, @order_ext, @line_no,  @part_no, 
					      @lot_ser,  @bin_no,    @location, @qty, @user_id,
					      @error_msg  OUTPUT

        -- If Pick fails, rollback and return    
	IF @return <> 0 
	BEGIN
		ROLLBACK TRAN
		RETURN -1	
	END

	-- Pack the part
	EXEC @return = tdc_packverify_pack_sp @order_no,    @order_ext,    @carton_no,  @line_no,   @part_no, @location,
					      @lot_ser,     @bin_no,       @qty,        @user_id,   @station_id, 
					      @carton_type, @carton_class, @not_using_orig_allocation, 
					      @error_msg  OUTPUT
							
        -- If Pack fails, rollback and return  
	IF @return <> 0 
	BEGIN
		ROLLBACK TRAN
		RETURN -2
	END

COMMIT TRAN
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_pickpack_sp] TO [public]
GO
