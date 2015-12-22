SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_clear_transfer_return_sp]	@spid	int 
AS
BEGIN
	DELETE FROM CVO_transfer_return WHERE spid = @spid
END
GO
GRANT EXECUTE ON  [dbo].[CVO_clear_transfer_return_sp] TO [public]
GO
