SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[fs_b60] @num int, @out varchar(20) out as

declare @x int
if @num = 0 select @out = '0' else select @out = ''
while (@num > 0)
  begin
    select @x = @num % 60
    if @x < 10 
      select @out = char(@x+ascii('0'))    + @out
    if @x >= 10 and @x < 35
      select @out = char(@x+ascii('A')-10) + @out
    if @x >= 35
      select @out = char(@x+ascii('a')-35) + @out
    select @num = (@num - @x) / 60
  end

GO
GRANT EXECUTE ON  [dbo].[fs_b60] TO [public]
GO
