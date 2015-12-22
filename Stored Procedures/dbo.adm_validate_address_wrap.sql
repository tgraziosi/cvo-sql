SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_validate_address_wrap] @trx_area char(2),
  @line1 varchar(40) OUT, @line2 varchar(40) OUT, @line3 varchar(40) OUT,
  @line4 varchar(40) OUT, @line5 varchar(40) OUT,
  @city varchar(40) OUT, @region varchar(40) OUT, @postalCode varchar(40) OUT, 
  @country varchar(40) OUT, @online_call int = 1, @debug int = 0
as 
set nocount on
declare @rc int
declare @addr_line_0 varchar(8000), @addr_line_1 varchar(8000)
declare @tpb_line varchar(10)
declare @cnt int, @lcnt int, @line varchar(255)

create table #address_data (orig_ind int, addr_ind int, addr_type varchar(50), addr_value varchar(255), sort_order int)

set @tpb_line = ''
if @line1 like '3PB=%' select @tpb_line = 'line1'
if @line2 like '3PB=%' select @tpb_line = 'line2'
if @line3 like '3PB=%' select @tpb_line = 'line3'
if @line4 like '3PB=%' select @tpb_line = 'line4'
if @line5 like '3PB=%' select @tpb_line = 'line5'

if @line1 	is not null insert #address_data values (1, 1, 'line1', 	@line1, 	1)
if @line2 	is not null insert #address_data values (1, 1, 'line2', 	@line2, 	2)
if @line3 	is not null insert #address_data values (1, 1, 'line3', 	@line3, 	3)
if @line4 	is not null insert #address_data values (1, 1, 'line4', 	@line4, 	4)
if @line5 	is not null insert #address_data values (1, 1, 'line5', 	@line5, 	5)
if @city 	is not null insert #address_data values (1, 2, 'city', 	@city, 		6)
if @region	is not null insert #address_data values (1, 2, 'region', 	@region, 	7)
if @postalCode 	is not null insert #address_data values (1, 2, 'postalcode', @postalCode, 	8)
if @country 	is not null insert #address_data values (1, 2, 'country', 	@country, 	9)

exec @rc = adm_validate_address @trx_area, @debug

if @rc = 1
begin
  if @tpb_line != ''
  begin
    insert #address_data (orig_ind , addr_ind , addr_type , addr_value , sort_order )
    select 0 , 1 , 'line5' , addr_value , 5 
    from  #address_data where orig_ind = 1 and addr_type = @tpb_line
  end

  select @addr_line_0 = '', @addr_line_1 = ''
  if not exists (select 1 from #address_data where lower(addr_type) = 'city' and orig_ind = 1
    and addr_value not in (select addr_value from #address_data where lower(addr_type) = 'city' and orig_ind = 0))
  begin
    if not exists (select 1 from #address_data where lower(addr_type) = 'region' and orig_ind = 1
      and addr_value not in (select addr_value from #address_data where lower(addr_type) = 'region' and orig_ind = 0))
    begin
      if not exists (select 1 from #address_data where lower(addr_type) = 'postalcode' and orig_ind = 1
        and addr_value not in (select addr_value from #address_data where lower(addr_type) = 'postalcode' and orig_ind = 0))
      begin
        if not exists (select 1 from #address_data where lower(addr_type) = 'country' and orig_ind = 1
          and addr_value not in (select addr_value from #address_data where lower(addr_type) = 'country' and orig_ind = 0))
        begin
          select @addr_line_0 = isnull((select addr_value from #address_data where lower(addr_type) = 'line1' and orig_ind = 0 and addr_value != ''),'')
          select @addr_line_0 = @addr_line_0 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line2' and orig_ind = 0 and addr_value != ''),'')
          select @addr_line_0 = @addr_line_0 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line3' and orig_ind = 0 and addr_value != ''),'')
          select @addr_line_0 = @addr_line_0 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line4' and orig_ind = 0 and addr_value != ''),'')
          select @addr_line_0 = @addr_line_0 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line5' and orig_ind = 0 and addr_value != ''),'')
          select @addr_line_1 = isnull((select addr_value from #address_data where lower(addr_type) = 'line1' and orig_ind = 1 and addr_value != ''),'')
          select @addr_line_1 = @addr_line_1 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line2' and orig_ind = 1 and addr_value != ''),'')
          select @addr_line_1 = @addr_line_1 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line3' and orig_ind = 1 and addr_value != ''),'')
          select @addr_line_1 = @addr_line_1 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line4' and orig_ind = 1 and addr_value != ''),'')
          select @addr_line_1 = @addr_line_1 + isnull((select '~!' + addr_value from #address_data where lower(addr_type) = 'line5' and orig_ind = 1 and addr_value != ''),'')

          if @addr_line_0 = @addr_line_1  set @rc = 2
        end
      end
    end
  end 
end

if @online_call = 1
begin
  select @rc, orig_ind, addr_ind, addr_type, addr_value, sort_order 
  from #address_data
   order by orig_ind, sort_order
end
else
begin
  if @rc > 0
  begin
    set @cnt = 1
    set @lcnt = 1
    select @line1 = '', @line2 = '', @line3 = '', @line4 = '', @line5 = ''
    while @cnt < 6
    begin
      select @line = isnull((select addr_value
        from #address_data where orig_ind = 0 and addr_ind = 1 and sort_order = @cnt),'')
      if @line like '3PB=%' set @lcnt = 5 
      if @line > ''
      begin
        if @lcnt = 1 select @line1 = @line
        if @lcnt = 2 select @line2 = @line
        if @lcnt = 3 select @line3 = @line
        if @lcnt = 4 select @line4 = @line
        if @lcnt = 5 select @line5 = @line
        select @lcnt = @lcnt + 1
      end
      select @cnt = @cnt + 1
    end

    select @city = isnull((select addr_value
      from #address_data where orig_ind = 0 and addr_ind = 2 and addr_type = 'city'),'')
    select @region = isnull((select addr_value
      from #address_data where orig_ind = 0 and addr_ind = 2 and addr_type = 'region'),'')
    select @postalCode = isnull((select addr_value
      from #address_data where orig_ind = 0 and addr_ind = 2 and addr_type = 'postalcode'),'')
    select @country = isnull((select addr_value
      from #address_data where orig_ind = 0 and addr_ind = 2 and addr_type = 'country'),'')
  end
end

return @rc

GO
GRANT EXECUTE ON  [dbo].[adm_validate_address_wrap] TO [public]
GO
