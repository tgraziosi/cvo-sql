SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_registration] @cmd char(1), @no int=0 AS

declare @err int, @rndbit int, @expdate int
declare @a int, @b int, @c int, @d int, @y int, @x varchar(10)
declare @i int, @chksum1 int, @chksum2 int, @chksum int
declare @regkey varchar(20), @regkey1 varchar(10), @regkey2 varchar(10), @regkey3 varchar(10), @regkey4 varchar(10), @regkey5 varchar(10)
declare @maxusers int, @currusers int, @n varchar(80)
declare @ser char(10), @ser2 varchar(20), @strdate varchar(6)
declare @testdate varchar(8), @testsum int
select @err=0
select @ser2 = min(serial_no) from registration
select @ser = substring( @ser2, 1, 5 ) + right( @ser2, 5 )
if (select count(*) from config where flag='INV_EOM_UPD' and value_str='YES') > 0
  begin
    if @cmd = 'M' 
      select 'Month-To-Date ( Year-To-Date ) updates in process.  Try again later.','Unlicensed Software - Owner Platinum','1',@ser
    return -7777
  end
if (select count(*) from registration) != 1
  begin
    if @cmd = 'M' 
      select 'Error 1 in Registration Table. Please re-enter.','Unlicensed Software - Owner Platinum','1',@ser
    return -1000
  end
if @cmd='C' or @cmd = 'M'
  begin
	select @i = 0
	select @chksum1 = 0
	select @chksum2 = 0
	while (@i < 80)
	  begin
	    select @chksum1 = @chksum1 + isnull((select ascii(substring(@n,@i,1))),@i)
	    select @chksum2 = @chksum2 + 255-isnull((select ascii(substring(@n,80-@i,1))),@i)
	    select @i = @i + 1
	  end
	select @chksum1 = @chksum1 ^ 532917
	select @chksum2 = @chksum2 ^ 956828
	select @chksum = @chksum1 ^ @chksum2
	select @a = convert(int,substring(@ser,4,1)+substring(@ser,8,1)+substring(@ser,3,1)
                    +substring(@ser,5,1)+substring(@ser,1,1))
	select @b = convert(int,substring(@ser,2,1)+substring(@ser,10,1)+substring(@ser,7,1)
                    +substring(@ser,9,1)+substring(@ser,6,1))
	select @c = isnull(((isnull(@a ^ 19056,19056) + 1200) ^ 73512),73512)
	select @d = isnull(((isnull(@b ^ 62953,62953) - 8165) ^ 83514),83514)
	select @regkey = (select min(reg_key) from registration)
	select @regkey1 = substring(@regkey,1,1)+substring(@regkey,6,1)+substring(@regkey,11,1)
	exec fs_b10 @regkey1, @rndbit out
	select @regkey2 = substring(@regkey,2,1) +substring(@regkey,7,1)+substring(@regkey,12,1)+substring(@regkey,16,1)
	select @regkey3 = substring(@regkey,3,1) +substring(@regkey,8,1)+substring(@regkey,13,1)+substring(@regkey,17,1)
	select @regkey4 = substring(@regkey,4,1) +substring(@regkey,9,1)+substring(@regkey,14,1)+substring(@regkey,18,1)
	select @i = 0
	select @y = 0
	while (@i < 30)
	  begin
	    select @y = @y + isnull((select ascii(substring(@regkey1+@regkey2+@regkey3+@regkey4,@i,1))),@i)
	    select @i = @i + 1
	  end
	exec fs_b60 @y, @x out
	select @regkey5 = @x
	while (datalength(@regkey5) < 3) 
	  select @regkey5 = '0'+@regkey5
	select @x = substring(@regkey,5,1) +substring(@regkey,10,1)+substring(@regkey,15,1)+substring(@regkey,19,1)
	if @regkey5 = @x
	  select @err=@err+0
	else
	  select @err=@err+1
	if @cmd = 'C'
	  begin
	    select @y = @no % (@err+ascii(@cmd)+datepart(weekday,getdate()))
	    return @y
	  end
	if @cmd = 'M' and @err <> 0
	  begin
	    select 'Error in Registration Key. Please re-enter.','Unlicensed Software - Owner Platinum','1',@ser
	    return 0
          end
  end 
if @cmd='N' or @cmd='M'
  begin
	select @n = (select min(name) from registration)
	select @i = 0
	select @chksum1 = 0
	select @chksum2 = 0
	while (@i < 80)
	  begin
	    select @chksum1 = @chksum1 + isnull((select ascii(substring(@n,@i,1))),@i)
	    select @chksum2 = @chksum2 + 255-isnull((select ascii(substring(@n,80-@i,1))),@i)
	    select @i = @i + 1
	  end
	select @chksum1 = @chksum1 ^ 532917
	select @chksum2 = @chksum2 ^ 956828
	select @chksum = @chksum1 ^ @chksum2
	select @regkey = (select min(reg_key) from registration)
	select @x = substring(@regkey,2,1) +substring(@regkey,7,1)
	           +substring(@regkey,12,1)+substring(@regkey,16,1)
	exec fs_b10 @x, @y out
	select @x = substring(@regkey,1,1)+substring(@regkey,6,1)+substring(@regkey,11,1)
	exec fs_b10 @x, @rndbit out
	select @testsum = (@y ^ @rndbit)
	if @testsum = @chksum
	  select @err=@err+0
	else
	  select @err=@err+1
	if @cmd='N'
	  begin
	    select @y = @no % (@err+ascii(@cmd)+datepart(weekday,getdate()))
	    return @y
	  end
	if @cmd = 'M' and @err <> 0
	  begin
	    select 'Error in User Name. Please re-enter.','Unlicensed Software - Owner Platinum','1',@ser
	    return 0
          end
  end 
if @cmd='U' or @cmd='M'
  begin
	select @n = (select min(name) from registration)
	select @i = 0
	select @chksum1 = 0
	select @chksum2 = 0
	while (@i < 80)
	  begin
	    select @chksum1 = @chksum1 + isnull((select ascii(substring(@n,@i,1))),@i)
	    select @i = @i + 1
	  end
	select @chksum1 = @chksum1 ^ 532917
	select @a = convert(int,substring(@ser,4,1)+substring(@ser,8,1)+substring(@ser,3,1)
                    +substring(@ser,5,1)+substring(@ser,1,1))
	select @c = isnull(((isnull(@a ^ 19056,19056) + 1200) ^ 73512),73512)
	select @regkey = (select min(reg_key) from registration)
	select @x = substring(@regkey,3,1) +substring(@regkey,8,1)+substring(@regkey,13,1)+substring(@regkey,17,1)
	exec fs_b10 @x, @y out
	select @x = substring(@regkey,1,1)+substring(@regkey,6,1)+substring(@regkey,11,1)
	exec fs_b10 @x, @rndbit out
	select @maxusers = ((@y ^ @rndbit) ^ @c) ^ @chksum1
	if @maxusers % 13 <> 0
	  begin
	    if @cmd = 'M' 
	      select 'Error 2 in Registration Table. Please re-enter.','Unlicensed Software - Owner Platinum','1',@ser
	    return -1000
	  end
	else
	  select @maxusers = @maxusers / 13
	select @currusers=(select count(*) from master..sysprocesses where dbid = (select db_id()))
	if @currusers<@maxusers 
	    select @err=@err+0
	if @currusers<@maxusers+5 and @currusers>@maxusers
	    select @err=@err+1
	if @currusers>=@maxusers+5 
	    select @err=@err+1
	if @cmd = 'U'
	  begin
	    select @y = @no % (@err+ascii(@cmd)+datepart(weekday,getdate()))
	    return @y
	  end
	if @cmd = 'M' and @err <> 0
	  begin
	    select 'Too many users on system.','Unlicensed Software - Owner Platinum','1',@ser
	    return 0
          end
  end 
if @cmd='D' or @cmd='M'
  begin
	select @n = (select min(name) from registration)
	select @i = 0
	select @chksum1 = 0
	select @chksum2 = 0
	while (@i < 80)
	  begin
	    select @chksum2 = @chksum2 + 255-isnull((select ascii(substring(@n,80-@i,1))),@i)
	    select @i = @i + 1
	  end
	select @chksum2 = @chksum2 ^ 956828
	select @b = (select convert(int,substring(@ser,2,1)+substring(@ser,10,1)+substring(@ser,7,1)
                     +substring(@ser,9,1)+substring(@ser,6,1)) from registration)
	select @d = isnull(((isnull(@b ^ 62953,62953) - 8165) ^ 83514),83514)
	select @regkey = (select min(reg_key) from registration)
	select @x = substring(@regkey,4,1) +substring(@regkey,9,1)+substring(@regkey,14,1)+substring(@regkey,18,1)
	exec fs_b10 @x, @y out
	select @x = substring(@regkey,1,1)+substring(@regkey,6,1)+substring(@regkey,11,1)
	exec fs_b10 @x, @rndbit out
	select @expdate = ((@y ^ @rndbit) ^ @d) ^ @chksum2
	select @strdate = convert(char,@expdate)
	select @testdate = substring(@strdate,1,2)+'/'+substring(@strdate,5,2)+'/'+substring(@strdate,3,2)
	if substring(@strdate,5,2) = '99' 
	  select @err=@err+0
	else
	  if convert(datetime,getdate(),1) < convert(datetime,@testdate,1) 
	    select @err=@err+0
	  else
	    select @err=@err+1
	if @cmd='D'
	  begin
	    select @y = @no % (@err+ascii(@cmd)+datepart(weekday,getdate()))
	    return @y
	  end
	if @cmd = 'M' and @err <> 0
	  begin
	    select 'Past expiration date.','Unlicensed Software - Owner Platinum','1',@ser
	    return 0
          end
  end 
if @cmd='M'
  begin
	select '',@n,convert(char(10),@maxusers),@ser
	return 0
  end
select 'Error in Registration. Please re-enter.','Unlicensed Software - Owner Platinum','1',@ser
return -1000

GO
GRANT EXECUTE ON  [dbo].[fs_registration] TO [public]
GO
