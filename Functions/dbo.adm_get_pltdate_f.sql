SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create function [dbo].[adm_get_pltdate_f] ( @date datetime) 
  returns int
begin
declare @pltdate int

select @pltdate = datediff(day,'1/1/1950',convert(datetime,
  convert(varchar(8), (year(@date) * 10000) + (month(@date) * 100) + day(@date)))  ) + 711858

return @pltdate
end
GO
GRANT REFERENCES ON  [dbo].[adm_get_pltdate_f] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_get_pltdate_f] TO [public]
GO
