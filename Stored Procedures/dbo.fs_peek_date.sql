SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[fs_peek_date] as

declare @err int, @rndbit int, @expdate int
declare @a int, @b int, @c int, @d int, @y int, @x varchar(10)
declare @i int, @chksum1 int, @chksum2 int, @chksum int
declare @regkey varchar(20), @regkey1 varchar(10), @regkey2 varchar(10), @regkey3 varchar(10), @regkey4 varchar(10), @regkey5 varchar(10)
declare @n varchar(80)
select @n = (select min(name) from registration)
select @i = 0
select @chksum2 = 0
if (select count(*) from registration) > 1
  select @err = 1
while (@i < 80)
  begin
    select @chksum2 = @chksum2 + 255-isnull((select ascii(substring(@n,80-@i,1))),@i)
    select @i = @i + 1
  end
select @chksum2 = @chksum2 ^ 956828
declare @ser varchar(10)
select @ser = (select min(serial_no) from registration)
select @b = (select convert(int,substring(@ser,2,1)
                       +substring(@ser,10,1)
                       +substring(@ser,7,1)
                       +substring(@ser,9,1)
                       +substring(@ser,6,1)) from registration)
select @d = isnull(((isnull(@b ^ 62953,62953) - 8165) ^ 83514),83514)
select @regkey = (select min(reg_key) from registration)
select @x = substring(@regkey,4,1) +substring(@regkey,9,1)
           +substring(@regkey,14,1)+substring(@regkey,18,1)
exec fs_b10 @x, @y out
select @x = substring(@regkey,1,1)+substring(@regkey,6,1)+substring(@regkey,11,1)
exec fs_b10 @x, @rndbit out
select @expdate = ((@y ^ @rndbit) ^ @d) ^ @chksum2
declare @strdate varchar(6)
select @strdate = convert(char,@expdate)
declare @testdate varchar(8)
select @testdate = substring(@strdate,1,2)+'/'+substring(@strdate,5,2)+'/'+substring(@strdate,3,2)
if substring(@strdate,5,2) = '99' 
  select 'never expires'
else
  select convert(datetime,@testdate)

GO
GRANT EXECUTE ON  [dbo].[fs_peek_date] TO [public]
GO
