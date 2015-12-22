SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_packverify_un_packpick_sp] 
	@order_no 	int,
	@order_ext 	int,
	@carton_no 	int,
	@line_no 	int, 
	@part_no 	varchar(30), 
	@location 	varchar(10), 
	@lot_ser	varchar(25),
	@bin_no  	varchar(12),
	@qty 		decimal(24,8), 
	@user_id 	varchar(50),
	@error_msg 	varchar(255) OUTPUT
AS

DECLARE @return	int

BEGIN TRAN
	-- Un-Pack the part
	EXEC @return = tdc_packverify_unpack_sp @order_no,  @order_ext, @carton_no, @line_no,  @part_no, 
						    @location,  @lot_ser,   @bin_no,    @qty,      @user_id,
						    @error_msg  OUTPUT

        -- If Un-Pack fails, rollback and return    
	IF @return < 0 
	BEGIN
		ROLLBACK TRAN
		RETURN -1	
	END
							
        -- If Un-Pick fails, rollback and return  
	EXEC @return = tdc_packverify_unpick_sp @order_no,  @order_ext, @line_no,  @part_no, @location,  
						    @lot_ser,   @bin_no,    @qty,      @user_id, @error_msg OUTPUT
						    
	IF @return < 0 
	BEGIN
		ROLLBACK TRAN
		RETURN -2
	END

COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_un_packpick_sp] TO [public]
GO
