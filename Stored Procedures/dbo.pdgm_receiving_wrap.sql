SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[pdgm_receiving_wrap]   @po_ctrl_num  varchar(16)  AS

BEGIN

DECLARE @msg  int

exec dbo.pdgm_receiving   @po_ctrl_num,  @msg OUT

SELECT @msg

END
GO
GRANT EXECUTE ON  [dbo].[pdgm_receiving_wrap] TO [public]
GO
