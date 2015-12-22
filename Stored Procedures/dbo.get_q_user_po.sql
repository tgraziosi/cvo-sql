SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_user_po] @void char(1) ,@sys_stat char(1)

AS

set rowcount 100

select 	user_stat_code, user_stat_desc, status_code, void
from 	po_usrstat ( NOLOCK )
where 	(void is NULL OR void like @void)
AND	status_code = @sys_stat
order by user_stat_code
GO
GRANT EXECUTE ON  [dbo].[get_q_user_po] TO [public]
GO
