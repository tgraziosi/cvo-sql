SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[fs_b10] @num varchar(20), @out int out as

declare @x char(1), @pos int
select @out = 0
while (datalength(@num) > 0)
  begin
    select @x = (select reverse(right(reverse(@num),1)))
    select @out = @out * 60
    if @x >= '0' and @x <= '9'
      select @out = @out + ascii(@x) - ascii('0')
    if ascii(@x) >= ascii('A') and ascii(@x) <= ascii('Z')
      select @out = @out + 10 + ascii(@x) - ascii('A')
    if ascii(@x) >= ascii('a') and ascii(@x) <= ascii('z')
      select @out = @out + 35 + ascii(@x) - ascii('a')
    select @num = right(@num,datalength(@num)-1)
  end

GO
GRANT EXECUTE ON  [dbo].[fs_b10] TO [public]
GO
