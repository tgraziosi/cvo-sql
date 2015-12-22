SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_email_get_next_cword] @email_type varchar(50), @seq_id int,
@dv varchar(7900) OUT, @cword varchar(7900) OUT
as
begin
declare @epos1 int, @epos2 int, @epos3 int, @epos4 int

set @cword = ''

if left(@dv,1) != '\'
  return -1

if substring(@dv,2,1) in ('\','{','}')
  return -2

set @cword = left(@dv,1)
set @dv = substring(@dv,2,datalength(@dv))
while 1=1
begin
  if left(@dv,1) in ('\','{','}')
    break
  if left(@dv,1) = ' '
  begin
    set @dv = substring(@dv,2,datalength(@dv))
    break
  end

  set @cword = @cword + left(@dv,1)
  set @dv = substring(@dv,2,datalength(@dv))
end

if @cword != ''
  return 1
else
  return -1
end
GO
GRANT EXECUTE ON  [dbo].[adm_email_get_next_cword] TO [public]
GO
