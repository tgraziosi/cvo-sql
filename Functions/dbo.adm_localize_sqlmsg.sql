SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create function [dbo].[adm_localize_sqlmsg] (@in_msg varchar(1000) )
returns varchar(1000)
as
begin
declare @out_msg varchar(1000)
declare @parm_cnt int, @start int, @end int, @cnt int
declare @value varchar(1000), @values varchar(1000)
declare @lang_id int
declare @newid uniqueidentifier

set @lang_id = 0
set @parm_cnt = 0
set @values = ''
select @start = charindex('[',@in_msg)
select @end = case when @start = 0 then 0 else charindex(']',@in_msg, @start) end

while @end <> 0
begin
	select @value = substring(@in_msg,@start +1, @end - @start -1)
	select @parm_cnt = @parm_cnt + 1
	select @in_msg = left(@in_msg,@start -1) + ':' + convert(varchar(10),@parm_cnt) + substring(@in_msg,@end + 1,1000)
	select @values = @values + @value + ','
	select @start = charindex('[',@in_msg)
	select @end = case when @start = 0 then 0 else charindex(']',@in_msg, @start) end
end

select @out_msg = s.stringtext
from adm_localization l (nolock)
join adm_strings_vw s (nolock) on s.languageid = l.lang_id and s.stringid = l.stringid
join adm_strings_vw o (nolock) on o.languageid = 0 and o.stringid  = l.orig_stringid
  and o.stringtext = @in_msg
where l.lang_id = @lang_id

if @@rowcount = 0
  set @out_msg = @in_msg

if @parm_cnt > 0 
begin
	select @values = substring(@values,1,1000)
    set @cnt = 0
    while @cnt < @parm_cnt
    begin
      select @cnt = @cnt + 1
	  select @value = substring(@values,1, charindex(',',@values) -1)
	  select @values = substring(@values,charindex(',', @values) + 1,1000)
	  select @out_msg = replace(@out_msg, ':' + convert(varchar(10), @cnt), @value)
	end
end

return @out_msg
end
GO
GRANT REFERENCES ON  [dbo].[adm_localize_sqlmsg] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_localize_sqlmsg] TO [public]
GO
