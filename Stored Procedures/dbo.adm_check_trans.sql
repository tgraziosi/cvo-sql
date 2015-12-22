SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_check_trans]  AS

DECLARE @err int

BEGIN

--Return QTY found in cost layer for specific tranasaction!
-- Do a no lock??I don't think so but need to check on it.


select @err = count(*) from in_gltrxdet (nolock) where posted_flag in ('N','W')


select @err

END
GO
GRANT EXECUTE ON  [dbo].[adm_check_trans] TO [public]
GO
