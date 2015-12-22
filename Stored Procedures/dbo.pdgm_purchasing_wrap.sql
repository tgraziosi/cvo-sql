SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[pdgm_purchasing_wrap]  @po_ctrl_num  varchar(16)    AS

BEGIN

DECLARE  @msg int

EXEC   pdgm_purchasing  @po_ctrl_num,  @msg OUTPUT 

SELECT @msg

END
GO
GRANT EXECUTE ON  [dbo].[pdgm_purchasing_wrap] TO [public]
GO
