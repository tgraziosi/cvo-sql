SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_print_plw_so_consolidated_pick_ticket_wrap_sp]  
 @user_id			varchar(50),  
 @station_id		varchar(20),  
 @order_no			int,  
 @order_ext			int,  
 @location			varchar(10)
AS  
BEGIN 
	SET NOCOUNT ON
	
	DECLARE @consolidation_no INT

	SELECT 
		@consolidation_no = mp_consolidation_no 
	FROM 
		#so_pick_ticket_details 
	WHERE 
		order_no = @Order_No 
		AND order_ext = @Order_Ext 
		AND location = @location 
		AND sel_flg <> 0

	IF ISNULL(@consolidation_no,0) <> 0
	BEGIN
		EXEC cvo_print_plw_so_consolidated_pick_ticket_sp @user_id, @station_id, @order_no, @order_ext, @location, @consolidation_no
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_print_plw_so_consolidated_pick_ticket_wrap_sp] TO [public]
GO
