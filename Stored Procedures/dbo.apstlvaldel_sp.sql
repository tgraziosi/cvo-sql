SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[apstlvaldel_sp] @debug_level smallint = 0
AS



IF EXISTS (
	SELECT trx_ctrl_num
	FROM	#apinppyt3450
	WHERE	printed_flag=1)
	
SELECT 1

ELSE
	SELECT 0

GO
GRANT EXECUTE ON  [dbo].[apstlvaldel_sp] TO [public]
GO
