SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_asm] @drow_id int    AS



declare @qty decimal(20,8), @maxdt datetime, @cnt int, @maxcnt int, @mindt datetime,
	@rqty decimal(20,8), @pqty decimal(20,8), @gotres int, @gotitem int, @parent varchar(30),
	@loc varchar(10), @src char(1), @srcno varchar(20), @dt datetime, @lev int,
	@dqty decimal(20,8)

select @loc=location, @parent=part_no, @qty=qty, @dt=demand_date, @src=source,
	@srcno=source_no, @lev=ilevel
	from resource_demand where row_id=@drow_id



select @gotres=(select count(*) from resource_demand
	where location=@loc and ilevel=(@lev + 1) and parent=@parent and 
	source=@src and source_no=@srcno and type = 'R')

select @gotitem=(select count(*) from resource_demand
	where location=@loc and ilevel=(@lev + 1) and parent=@parent and 
	source=@src and source_no=@srcno and type <> 'R') 

if @gotitem > 0 begin
 select @qty=min(floor((r.commit_ed - r.p_used) / pqty)) from resource_demand r
	where r.location=@loc and r.ilevel=(@lev + 1) and r.parent=@parent and 
	r.source=@src and r.source_no=@srcno and
	r.type <> 'R' and r.pqty <> 0 
  select @qty=0 where @qty is null

  select @maxdt=max(avail_date) from resource_depends d, resource_demand r
	where (r.location=@loc and r.ilevel=(@lev + 1) and r.parent=@parent and 
	r.source=@src and r.source_no=@srcno and r.type <> 'R') and
	d.location=@loc and d.ilevel=(@lev + 1) and d.part_no=r.part_no and 

	d.demand_source_no=@src and d.demand_source_no=@srcno   
	group by d.parent
	order by d.parent
	end


select @pqty=99999999
if @maxdt is null select @maxdt=getdate()
if @gotitem = 0 begin


	
	select @qty=999999999
	select @maxdt=getdate()
	end

if @gotitem > 0 and @qty > 0 and @gotres=0 
	begin
  select @maxcnt=max(cnt) + 1 from resource_sch
  select @maxcnt=1 where @maxcnt is null
  update resource_demand set p_used=p_used + (@qty * pqty) from resource_demand 
	where location=@loc and ilevel=(@lev + 1) and parent=@parent and 
	source=@src and source_no=@srcno 

  insert resource_sch (part_no,qty,sch_date,ilevel,location,source,demand_date,demand_qty,demand_source,cnt,demand_source_no,end_sch_date,type)
  select @parent, @qty, @maxdt, @lev, @loc, 'D', @dt, 
	@dqty, @src, @maxcnt, @srcno, @maxdt, i.status from
 	inventory i where i.part_no=@parent and i.location=@loc
	return 1
	end 
if @gotres > 0 and @qty > 0
	begin

  

  select @mindt=min(avail_date), @maxdt=max(avail_date) from resource_depends d, resource_demand r
	where (r.location=@loc and r.ilevel=(@lev + 1) and r.parent=@parent and 
	r.source=@src and r.source_no=@srcno and r.type='R') and
	d.location=@loc and d.ilevel=@lev and d.part_no=r.part_no and 
	d.demand_source=@src and d.demand_source_no=@srcno 
	group by d.parent	
	order by d.parent

  if @mindt is null select @mindt=getdate()

  if @maxdt is null select @maxdt=@mindt
  select @rqty=min(floor((commit_ed - p_used) / pqty)) from resource_demand
	where location=@loc and ilevel=(@lev + 1) and parent=@parent and 
	source=@src and source_no=@srcno and type = 'R' and pqty <> 0 

  if @rqty is null begin
	select @rqty=0  
   end 	
 
  select @pqty=commit_ed - p_used from resource_demand

	where location=@loc and ilevel=(@lev + 1) and parent=@parent and 
	source=@src and source_no=@srcno and type = 'R' and pqty = 0 
  if @pqty is null begin
	select @pqty=0  
   end 	
  if @rqty < @qty begin

	select @qty=@rqty
	end
  if @pqty < @qty begin

	select @qty=@pqty
	end  
  if @qty > 0 begin
	
  select @maxcnt=max(cnt) + 1 from resource_sch
  select @maxcnt=1 where @maxcnt is null
  update resource_demand set p_used=p_used + (@qty * pqty) from resource_demand
	where location=@loc and ilevel=(@lev + 1) and parent=@parent and 
	source=@src and source_no=@srcno 

  insert resource_sch (part_no,qty,sch_date,ilevel,location,source,demand_date,demand_qty,demand_source,cnt,demand_source_no,end_sch_date,type)
	select @parent, @qty, @maxdt, @lev, @loc, 'D', @dt, 
	@dqty, @src, @maxcnt, @srcno, @maxdt, i.status from
 	inventory i where i.part_no=@parent and i.location=@loc
	return 1
	end 

end

return 0


GO
GRANT EXECUTE ON  [dbo].[fs_sch_asm] TO [public]
GO
