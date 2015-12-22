SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_email_insert_parm] @parms varchar(1000), @dtl_line varchar(7900) OUT, @width int
as
begin
declare @parm_cnt int, @cnt int, @begin int
declare @parm_value varchar(1000), @data varchar(100)
declare @st_pos int, @en_pos int
set @parms = isnull(@parms,'')
if left(@parms,2) != '<@'
begin
  if charindex(';',@parms) > 0
  begin
    set @parm_cnt = datalength(@parms)
    set @cnt = 1
    set @begin = 1
    while (@begin <= @parm_cnt)
    begin
      set @parm_value = substring(@parms,@begin,charindex(';',@parms,@begin))
      set @parm_value = left(@parm_value,datalength(@parm_value) -1)
      set @begin = charindex(';',@parms, @begin) + 1

      select @dtl_line = replace(@dtl_line,'<@parm' + convert(varchar,@cnt) + '>',@parm_value)
      select @cnt = @cnt + 1
    end
  end
  set @dtl_line = dbo.adm_email_insert_parm ('<@date',@dtl_line, @width)
  set @dtl_line = dbo.adm_email_insert_parm ('<@time',@dtl_line, @width)
  set @dtl_line = dbo.adm_email_insert_parm ('<@comp_name',@dtl_line, @width)
end
else
begin
  set @st_pos = charindex(@parms,@dtl_line)
  if @st_pos > 0
  begin
    set @en_pos = charindex('>', @dtl_line, @st_pos)
    set @data = substring(@dtl_line, @st_pos + 6,@en_pos - (@st_pos + 6))
    if left(@data,1) = ',' set @data = substring(@data,2,100)
    if @parms = '<@date' and @data = '' set @data = 110
    set @dtl_line = left(@dtl_line, @st_pos -1) + 
    case @parms 
      when '<@date' then convert(varchar,getdate(),cast(@data as int)) 
      when '<@time' then convert(varchar(8),getdate(),114) 
      when '<@comp_name' then (select company_name from arco)
      else ''
    end +
      substring(@dtl_line, @en_pos +1, datalength(@dtl_line))
  end
end
end
GO
GRANT EXECUTE ON  [dbo].[adm_email_insert_parm] TO [public]
GO
