SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ep_get_accdef] 
as
set nocount on

declare @rc int

select acct_format, description, start_col, length, acct_level, natural_acct_flag 
from glaccdef
order by acct_level

select @rc = 1


return @rc

GO
GRANT EXECUTE ON  [dbo].[adm_ep_get_accdef] TO [public]
GO
