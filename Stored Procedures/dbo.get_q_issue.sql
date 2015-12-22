SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_issue]  @info varchar(30), @sort char(2), @issno int  AS

declare @sort1 char(1), @cycind char(1), @reason varchar(10)		-- mls 3/22/01 SCR 26311

select @sort1 = substring(@sort,1,1)					-- mls 3/22/01 SCR 26311 start
select @cycind = '', @reason = '%'
if datalength(@sort) > 1
begin
  select @cycind = substring(@sort,2,1)
  if @cycind = 'C'	select @reason = 'cycle%'
end 									
select @sort = @sort1							-- mls 3/22/01 SCR 26311 end

set rowcount 100
if @sort='D'
begin
select issue_no, part_no, location_from, location_to, code, issue_date, qty
from issues_all ( NOLOCK ), locations (nolock)
where issues_all.issue_date >= @info AND issues_all.issue_no >= @issno
and isnull(lower(reason_code),'') like @reason				-- mls 3/22/01 SCR 26311
and issues_all.location_from = locations.location
order by issue_date, part_no
end
if @sort='P'
begin
select issue_no, part_no, location_from, location_to, code, issue_date, qty
from issues_all ( NOLOCK ), locations (nolock)
where issues_all.part_no >= @info AND issues_all.issue_no >= @issno
and isnull(lower(reason_code),'') like @reason				-- mls 3/22/01 SCR 26311
and issues_all.location_from = locations.location
order by part_no
end
if @sort='N'
begin
declare @x int
select @x=convert(int,@info)
select issue_no, part_no, location_from, location_to, code, issue_date, qty
from issues_all ( NOLOCK ), locations (nolock)
where issues_all.issue_no >= @x
and isnull(lower(reason_code),'') like @reason				-- mls 3/22/01 SCR 26311
and issues_all.location_from = locations.location
order by issue_no
end

GO
GRANT EXECUTE ON  [dbo].[get_q_issue] TO [public]
GO
