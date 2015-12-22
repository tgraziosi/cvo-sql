SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


Create Procedure [dbo].[adm_parse_address]
  @nonupdate_ind int = 1, 
  @select_ind int = 0,
  @addr1 varchar(255) OUT, @addr2 varchar(255) OUT, @addr3 varchar(255) OUT, @addr4 varchar(255) OUT,
  @addr5 varchar(255) OUT, @addr6 varchar(255) OUT,
  @city varchar(255) = '' OUT, @state varchar(255) = '' OUT, @zip varchar(255) = '' OUT,
  @country_cd varchar(3) = '' OUT, @country varchar(255) = '' OUT
as
begin


declare @a1 varchar(255), @a2 varchar(255), @a3 varchar(255), @a4 varchar(255), @a5 varchar(255),
  @a6 varchar(255), @acnt int, @ccnt int, @a varchar(255), @mcnt int,
  @pos int, @rc int,
  @acity varchar(255), @astate varchar(255), @azip varchar(255)
declare @addr_line_0 varchar(2000), @addr_line_1 varchar(2000)

set @rc = 1
set @acnt = 1
set @ccnt = 0
select @acity = '', @astate = '', @azip = ''

while @acnt < 7
begin
  select @a = case @acnt 
	when 1 then ltrim(@addr1)
	when 2 then ltrim(@addr2)
	when 3 then ltrim(@addr3)
	when 4 then ltrim(@addr4)
	when 5 then ltrim(@addr5)
	when 6 then ltrim(@addr6)
	end,
    @acnt = @acnt + 1

  if isnull(@a,'') = ''
    CONTINUE
  if @a like '3PB=%'
    CONTINUE

  select @ccnt = @ccnt + 1
  if @ccnt = 1  select @a1 = @a
  if @ccnt = 2  select @a2 = @a
  if @ccnt = 3  select @a3 = @a
  if @ccnt = 4  select @a4 = @a
  if @ccnt = 5  select @a5 = @a
  if @ccnt = 6  select @a6 = @a
end

if @ccnt <= 1
begin
  if @select_ind = 1 
  select left(@addr1,40) addr1,  left(@addr2,40) addr2, left(@addr3,40) addr3, left(@addr4,40) addr4,
    left(@addr5,40) addr5, left(@addr6,40) addr6,
    left(@city,40) city, left(@state,40) state, left(@zip,15) zip, left(@country_cd,3) country_cd, 
    left(@country,40) country
  return
end

select @mcnt = @ccnt

set @acnt = 1
while @ccnt > 0 and @acnt < 4
begin
  select @a = rtrim(case @ccnt 
	when 1 then @a1
	when 2 then @a2
	when 3 then @a3
	when 4 then @a4
	when 5 then @a5
	when 6 then @a6
	end),
    @ccnt = @ccnt - 1

  select @a = Reverse(@a)

  -- Zip Code
  if @acnt = 1
  begin
    if charindex(' ', @a) > 0
    begin
      select @azip = ltrim(Reverse(substring(@a,1, ( charindex(' ', @a) - 1))))
      select @a = ltrim( substring(@a, ( charindex(' ', @a)), 255)) 
    end
    else
      select @azip = Reverse(@a),
        @a = ''

      if upper(@azip) like '[0-9][A-Z][0-9]' -- Canadian postal codes in ANA NAN format
      begin
        if charindex(' ', @a) > 0
        begin
          select @azip = ltrim(Reverse(substring(@a,1, ( charindex(' ', @a) - 1)))) + ' ' + @azip
          select @a = ltrim( substring(@a, ( charindex(' ', @a)), 255)) 
        end
        else
          select @azip = Reverse(@a) + ' ' + @azip,
            @a = ''
      end

      if @nonupdate_ind = 0
      begin
        if @ccnt = 0 set @a1 = reverse(@a)
        if @ccnt = 1 set @a2 = reverse(@a)
        if @ccnt = 2 set @a3 = reverse(@a)
        if @ccnt = 3 set @a4 = reverse(@a)
        if @ccnt = 4 set @a5 = reverse(@a)
        if @ccnt = 5 set @a6 = reverse(@a)
      end

    select @acnt = @acnt + 1
    if @a = ''  
      CONTINUE
  end

  -- State
  if @acnt = 2
  begin
    set @pos = charindex(',', @a)
    if @pos = 0 
      set @pos = charindex(' ', @a)
      
    if @pos > 0
    begin
      select @astate = ltrim(Reverse(substring(@a,1, ( @pos - 1))))
      select @a = ltrim( substring(@a, ( @pos), 255)) 
      if substring(@a, 1, 1) = ','
        select @a = ltrim( substring(@a, 2, 255))
      else
       select @a = ltrim(@a)
    end
    else
    begin
      select @astate = Reverse(@a),
        @a = ''

      if @nonupdate_ind = 0
      begin
        if @ccnt = 0 set @a1 = reverse(@a)
        if @ccnt = 1 set @a2 = reverse(@a)
        if @ccnt = 2 set @a3 = reverse(@a)
        if @ccnt = 3 set @a4 = reverse(@a)
        if @ccnt = 4 set @a5 = reverse(@a)
        if @ccnt = 5 set @a6 = reverse(@a)
      end

      if @acnt = @mcnt and datalength(@astate) < 2
        select @astate = '', @azip = ''
    end

    select @acnt = @acnt + 1
    if @a = ''  
      CONTINUE
  end

  -- City
  if @acnt = 3
  begin
    if @astate = ''
    begin
      select @acnt = 4
      CONTINUE
    end

    select @acity = ltrim(Reverse(@a))
    select @acnt = 4
    select @a = ''

      if @nonupdate_ind = 0
      begin
        if @ccnt = 0 set @a1 = reverse(@a)
        if @ccnt = 1 set @a2 = reverse(@a)
        if @ccnt = 2 set @a3 = reverse(@a)
        if @ccnt = 3 set @a4 = reverse(@a)
        if @ccnt = 4 set @a5 = reverse(@a)
        if @ccnt = 5 set @a6 = reverse(@a)
      end

  end
end

select @a1 = isnull(@a1,''),
  @a2 = isnull(@a2,''),
  @a3 = isnull(@a3,''),
  @a4 = isnull(@a4,''),
  @a5 = isnull(@a5,''),
  @a6 = isnull(@a6,''),
  @acity = isnull(@acity,''),
  @astate = isnull(@astate,''),
  @azip = isnull(@azip,'')


select @addr_line_1 = @a1 + '~!' + @a2 + '~!' + @a3 + '~!' + @a4 + '~!' + @a5 + '~!' + @a6
  + '~!' + @acity + '~!' + @astate + + '~!' + @azip 
select @addr_line_0 = isnull(@addr1,'') + '~!' + isnull(@addr2,'')  + '~!' + isnull(@addr3,'')  
  + '~!' + isnull(@addr4,'')  + '~!' + isnull(@addr5,'')  + '~!' + isnull(@addr6,'') 
  + '~!' + isnull(@city,'') + '~!' + isnull(@state,'') +  '~!' + isnull(@zip,'') 

if @addr_line_0 = @addr_line_1  set @rc = 2

if @nonupdate_ind = 0
  select @addr1 = @a1,
    @addr2 = @a2,
    @addr3 = @a3,
    @addr4 = @a4,
    @addr5 = @a5,
    @addr6 = @a6

select
    @city = @acity,
    @state = @astate,
    @zip = @azip

if @select_ind = 1 
begin
  if @nonupdate_ind = 0
    select left(@a1,40) addr1,  left(@a2,40) addr2, left(@a3,40) addr3, left(@a4,40) addr4,
      left(@a5,40) addr5, left(@a6,40) addr6,
      left(@acity,40) city, left(@astate,40) state, left(@azip,15) zip, left(@country_cd,3) country_cd, 
      left(@country,40) country
  if @nonupdate_ind = 1
    select left(@addr1,40) addr1,  left(@addr2,40) addr2, left(@addr3,40) addr3, left(@addr4,40) addr4,
      left(@addr5,40) addr5, left(@addr6,40) addr6,
      left(@acity,40) city, left(@astate,40) state, left(@azip,15) zip, left(@country_cd,3) country_cd, 
      left(@country,40) country
end

return @rc
end
GO
GRANT EXECUTE ON  [dbo].[adm_parse_address] TO [public]
GO
