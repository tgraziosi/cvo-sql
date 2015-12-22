SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apvocan_sp]
AS

DELETE #apinpchg

DELETE #apinpcdt

DELETE #apinpage

DELETE #apinptax

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apvocan_sp] TO [public]
GO
