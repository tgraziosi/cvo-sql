SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_phy_hdr]  @info varchar(30), @sort char(1), 
                                @stat char(1), @phybatch int  AS


declare @x int, @minstat char(1), @maxstat char(1)

select @minstat = @stat
select @maxstat = @stat

if @stat = 'A' select @maxstat = 'Z'

set rowcount 100

if @sort='N'
begin
select @x=convert(int,@info)
select phy_batch, description, date_init, who_init, status
from phy_hdr
where phy_batch >= @x and 
      status >= @minstat and status <= @maxstat
order by phy_batch
end

if @sort='D'
begin
select phy_batch, description, date_init, who_init, status
from phy_hdr
where phy_batch >= @phybatch and date_init >= @info and 
      status >= @minstat and status <= @maxstat
order by date_init, phy_batch
end


GO
GRANT EXECUTE ON  [dbo].[get_q_phy_hdr] TO [public]
GO
