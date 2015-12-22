SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create function [dbo].[adm_format_pltdate_f] ( @pltdate int) 
  returns datetime
begin
declare @date datetime, @year int, @mth int, @day int

if @pltdate = 0  return NULL
select @pltdate = @pltdate - 711858

select @date = dateadd(day,@pltdate,'1/1/1950')

return @date
end
GO
GRANT REFERENCES ON  [dbo].[adm_format_pltdate_f] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_format_pltdate_f] TO [public]
GO
