SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_user] 	@void char(1) , @system_status char(1) = '%'

AS

set rowcount 100

select 	user_stat_code, user_stat_desc, status_code, void
from 	so_usrstat ( NOLOCK )
where 	(void is NULL OR void like @void)
and status_code like @system_status	-- mls 9/25/06 SCR 36967
order by user_stat_code

GO
GRANT EXECUTE ON  [dbo].[get_q_user] TO [public]
GO
