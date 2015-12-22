SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[pdgm_po_matching_wrap]  @po_ctrl_num  varchar(16)  AS

BEGIN

DECLARE @msg  int

exec dbo.pdgm_po_matching  @po_ctrl_num,  @msg OUTPUT	

SELECT @msg

END
GO
GRANT EXECUTE ON  [dbo].[pdgm_po_matching_wrap] TO [public]
GO
