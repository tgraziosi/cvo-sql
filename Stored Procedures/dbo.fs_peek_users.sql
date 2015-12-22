SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[fs_peek_users] as

declare @a int, @b int, @c int, @d int, @y int, @x varchar(10)
declare @i int, @chksum1 int, @chksum2 int, @chksum int, @err int
declare @regkey varchar(20), @regkey1 varchar(10), @regkey2 varchar(10), @regkey3 varchar(10), @regkey4 varchar(10), @regkey5 varchar(10)
declare @n varchar(80)
select @n = (select min(name) from registration)
select @i = 0
select @chksum1 = 0
if (select count(*) from registration) > 1
  select @err = 1
while (@i < 80)
  begin
    select @chksum1 = @chksum1 + isnull((select ascii(substring(@n,@i,1))),@i)
    select @i = @i + 1
  end
select @chksum1 = @chksum1 ^ 532917
declare @ser varchar(10)
select @ser = (select min(serial_no) from registration)
select @a = convert(int,substring(@ser,4,1)
                       +substring(@ser,8,1)
                       +substring(@ser,3,1)
                       +substring(@ser,5,1)
                       +substring(@ser,1,1))
select @c = isnull(((isnull(@a ^ 19056,19056) + 1200) ^ 73512),73512)
select @regkey = (select min(reg_key) from registration)
select @x = substring(@regkey,3,1) +substring(@regkey,8,1)
           +substring(@regkey,13,1)+substring(@regkey,17,1)
exec fs_b10 @x, @y out
declare @rndbit int
select @x = substring(@regkey,1,1)+substring(@regkey,6,1)+substring(@regkey,11,1)
exec fs_b10 @x, @rndbit out
declare @maxusers int
select @maxusers = ((@y ^ @rndbit) ^ @c) ^ @chksum1
select @maxusers = @maxusers / 13
select @maxusers

GO
GRANT EXECUTE ON  [dbo].[fs_peek_users] TO [public]
GO
