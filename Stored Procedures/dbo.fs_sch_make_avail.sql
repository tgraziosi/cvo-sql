SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_make_avail]
  @part_no varchar(30), @loc varchar(10), @xdt datetime, @qty decimal(20,8), 
   @src char(1), @srcno varchar(20), @lev int , @parent varchar(30), @minord decimal(20,8)  AS
begin







	

declare @tqty decimal(20,8), @maxcnt int
select @tqty = @minord * (1 + floor((@qty - 1 ) / @minord))
if @tqty=0 return 0
if exists (select * from resource_demand where part_no=@part_no and location=@loc and

	demand_date=@xdt and source='F' and ilevel=@lev and status='A' )
	begin
update resource_demand set qty=qty+@tqty from resource_demand 
	where part_no=@part_no and location=@loc and
	demand_date=@xdt and source='F' and ilevel=@lev and status='A' 
update resource_avail set qty=qty+@tqty, status='N' where source='F' and part_no=@part_no and
	avail_date=@xdt and location=@loc
	end 
else
	begin
select @maxcnt=1 + (isnull((select convert(int,max(source_no)) from resource_demand where status='A'),0))
insert resource_avail (part_no, qty, avail_date, commit_ed, source, location, source_no,
 temp_qty, type, status)

 select @part_no, @tqty, @xdt, 0, 'F', @loc, convert(varchar(20),@maxcnt), 0, status , 'N'
 from inventory where @part_no=part_no and @loc=location 
insert resource_demand (ilevel, part_no, qty, demand_date, 
                        location, source, status, commit_ed, 

                        source_no, pqty, p_used, type, vendor, 
                        buy_flag, uom, parent)
select @lev, @part_no, @tqty ,@xdt,@loc, 'F', 'A', 0, convert(varchar(20), @maxcnt), 1, 0, status, vendor, 'N', uom, @parent
 from inventory where @part_no=inventory.part_no and @loc=inventory.location 
	end
end
return 1


GO
GRANT EXECUTE ON  [dbo].[fs_sch_make_avail] TO [public]
GO
