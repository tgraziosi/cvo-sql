SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CVO_clear_discount_adjustment_sp]													  
AS
BEGIN
	SET NOCOUNT ON

	DELETE FROM CVO_discount_adjustment_results WHERE spid = @@SPID
END 
	
GO
GRANT EXECUTE ON  [dbo].[CVO_clear_discount_adjustment_sp] TO [public]
GO
