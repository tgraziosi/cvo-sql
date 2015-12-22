SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_physical]  @info varchar(30), @sort char(1),
                                 @phybatch int, @phyno int  AS

set rowcount 100
if @sort='P'
begin
select phy_no, location, part_no, qty, orig_qty, who_entered, date_entered
from physical
where phy_batch = @phybatch and
      part_no >= @info and phy_no > @phyno
order by part_no, phy_no
end
if @sort='D'
begin
select phy_no, location, part_no, qty, orig_qty, who_entered, date_entered
from physical
where phy_batch = @phybatch and
      date_entered >= @info and phy_no > @phyno
order by date_entered, part_no, phy_no
end
if @sort='N'
begin
declare @x int
select @x=convert(int,@info)
select phy_no, location, part_no, qty, orig_qty, who_entered, date_entered
from physical
where phy_batch = @phybatch and
      phy_no >= @x
order by phy_no
end


GO
GRANT EXECUTE ON  [dbo].[get_q_physical] TO [public]
GO
