SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_produce]  @info varchar(30), @sort char(1), @prodno int, @status char(1), @loc varchar(10)  AS

set rowcount 100
declare @minstat char(1)
declare @maxstat char(1)
declare @x int
if @status = 'A' begin
select @minstat='A'
select @maxstat='Z'
end
if @status = 'N' begin
select @minstat='N'
select @maxstat='O'
end
if @status = 'P' begin
select @minstat='P'
select @maxstat='Q'
end
if @status = 'Q' begin
select @minstat='R'
select @maxstat='R'
end
if @status = 'S' begin
select @minstat='R'
select @maxstat='U'
end
if @sort='D'
begin
select prod_no, part_no, location, shift, prod_type, prod_date, qty, status
from produce ( NOLOCK )
where produce.prod_date >= @info and
produce.location like @loc and
produce.status>=@minstat and produce.status<=@maxstat
order by prod_date, part_no, prod_no
end
if @sort='P'
begin
select prod_no, part_no, location, shift, prod_type, prod_date, qty, status
from produce ( NOLOCK )
where produce.status>=@minstat and produce.status<=@maxstat and
produce.location like @loc and
( (produce.part_no > @info) OR (produce.part_no = @info and produce.prod_no >= @prodno) )
order by part_no,prod_date
end
if @sort='N'
begin
select @x=convert(int,@info)
select prod_no, part_no, location, shift, prod_type, prod_date, qty, status
from produce ( NOLOCK )
where produce.status>=@minstat and produce.status<=@maxstat and
produce.location like @loc and
produce.prod_no >= @x
order by prod_no
end

GO
GRANT EXECUTE ON  [dbo].[get_q_produce] TO [public]
GO
