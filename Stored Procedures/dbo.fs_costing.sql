SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[fs_costing] @pn varchar(30), @org varchar(30), @loc varchar(10) AS 
set nocount on



declare @x int, @y int, @max int
declare @location varchar(10), @msg varchar(50), @rollup char(1)

declare @cst_pct decimal(20,8)						

DECLARE @cost decimal(20,8),@direct decimal(20,8),@ovhd decimal(20,8),@util decimal(20,8), @eoq decimal(20,8)

select @x=0, @y=0, @max=10

if @pn<>'%'
begin
 select @max = 1
end

select @rollup = isnull((select value_str from config where flag = 'COST_ROLLUP'),'N')


CREATE TABLE #tloc ( tloc varchar(10), status char(1) NULL )

if @org != ''
begin
  INSERT #tloc 
  SELECT DISTINCT i.location,'N' FROM inv_list i, locations l (nolock) WHERE i.part_no=@pn and i.location = l.location
    and l.organization_id = @org
end
else
begin
  if @loc != ''
  begin
    INSERT #tloc 
    SELECT DISTINCT i.location,'N' FROM inv_list i, locations l (nolock) WHERE i.part_no=@pn and i.location = l.location
    and l.location = @loc
  end
  else
  begin
    INSERT #tloc 
    SELECT DISTINCT i.location,'N' FROM inv_list i, locations l (nolock) WHERE i.part_no=@pn and i.location = l.location
  end
end 

select @y = count(*) from #tloc where status='N'
while @y > 0
begin
 set rowcount 1
 select @location = tloc from #tloc where status='N'
 set rowcount 0

 
 while @x < @max
 begin

 select @eoq = isnull((select eoq
 from inv_list 
 where part_no = @pn AND				-- mls 3/24/99 EPR D3-276
 location = @location ),1)

 if @eoq = 0 select @eoq = 1				-- mls 3/24/99 EPR D3-276

 if @rollup = 'Y'
 BEGIN

 select @cst_pct = isnull(( select sum(cost_pct)	-- mls 3/24/99 EPR D3-276
	from what_part					-- mls 3/24/99 EPR D3-276
	where asm_no = @pn and active = 'M'),0)		-- mls 3/24/99 EPR D3-276
 select @cst_pct = 100 - @cst_pct			-- mls 3/24/99 EPR D3-276
 if @cst_pct < 0 	select @cst_pct = 0		-- mls 3/24/99 EPR D3-276
 select @cst_pct = @cst_pct / 100			-- mls 3/24/99 EPR D3-276


 select @cost = isnull( (select sum(b.std_cost * w.qty) 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active <= 'B' and 
 w.fixed != 'Y' and 
 b.location = @location and 
 (w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276
		
 select @direct = isnull( (select sum(b.std_direct_dolrs * w.qty) 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active <= 'B' and 
 w.fixed != 'Y' and 
 b.location = @location and 
 (w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276


 select @ovhd = isnull( (select sum(b.std_ovhd_dolrs * w.qty) 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active <= 'B' and 
 w.fixed != 'Y' and 
 b.location = @location and 
 (w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276
		
 select @util = isnull( (select sum(b.std_util_dolrs * w.qty) 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active <= 'B' and 
 w.fixed != 'Y' and 
 b.location = @location and 
 (w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

 
 select @cost = @cost + isnull( (select sum(b.std_cost * w.qty / @eoq)	-- mls 3/24/99 EPR d3-276 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active<='B' and 
 w.fixed = 'Y' and 
				-- mls 3/24/99 EPR d3-276
 b.location = @location and 
 ( w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

		
 select @direct = @direct + isnull( (select sum(b.std_direct_dolrs * w.qty / @eoq)	-- mls 3/24/99 EPR d3-276 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active<='B' and 
 w.fixed = 'Y' and 
				-- mls 3/24/99 EPR d3-276
 b.location = @location and 
 ( w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

 select @ovhd = @ovhd + isnull( (select sum(b.std_ovhd_dolrs * w.qty / @eoq)	-- mls 3/24/99 EPR d3-276 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active<='B' and 
 w.fixed = 'Y' and 
				-- mls 3/24/99 EPR d3-276
 b.location = @location and 
 ( w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276
		
 select @util = @util + isnull( (select sum(b.std_util_dolrs * w.qty / @eoq)	-- mls 3/24/99 EPR d3-276 
	 from inv_list b, what_part w
	 where w.asm_no = @pn and 
 b.part_no = w.part_no and 
 w.active<='B' and 
 w.fixed = 'Y' and 
				-- mls 3/24/99 EPR d3-276
 b.location = @location and 
 ( w.location = @location OR w.location = 'ALL' ) AND
	 ( exists (select * from what_part where what_part.asm_no=@pn) )), 0 ) 
 * @cst_pct						-- mls 3/24/99 EPR D3-276

 --Fixed with EOQ = 0	- commented out 3/24/99 mls epr d3-276
									-- mls 3/24/99 EPR d3-276

 update inv_list set std_cost = @cost + @direct + @ovhd + @util,
			std_direct_dolrs=0,
			std_ovhd_dolrs=0,
			std_util_dolrs=0
	 where inv_list.part_no = @pn AND 				-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )



 
 END --Rollup = 'Y'

 ELSE
 BEGIN

 select @cst_pct = isnull(( select sum(cost_pct)	-- mls 3/24/99 EPR D3-276
	from what_part					-- mls 3/24/99 EPR D3-276
	where asm_no = @pn and active = 'M'),0)		-- mls 3/24/99 EPR D3-276
 select @cst_pct = 100 - @cst_pct			-- mls 3/24/99 EPR D3-276
 if @cst_pct < 0 	select @cst_pct = 0		-- mls 3/24/99 EPR D3-276
 select @cst_pct = @cst_pct / 100			-- mls 3/24/99 EPR D3-276


 update inv_list 
 set std_cost=isnull( (select sum(b.std_cost * w.qty) 
 from inv_list b, what_part w
 where w.asm_no = inv_list.part_no and 
 b.part_no = w.part_no and 
 w.active <='B' and 
 w.fixed != 'Y' and 
 b.location = @location and 
 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )
		
 update inv_list 
 set std_direct_dolrs=isnull( (select sum(b.std_direct_dolrs * w.qty) 
 	 from inv_list b, what_part w
 	 where w.asm_no=inv_list.part_no and b.part_no=w.part_no and w.active<='B' and w.fixed != 'Y'
 					 and b.location = @location and 
 				 	 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )

 update inv_list set std_ovhd_dolrs=isnull( (select sum(b.std_ovhd_dolrs * w.qty) 
	 from inv_list b, what_part w
	 where w.asm_no=inv_list.part_no and b.part_no=w.part_no and w.active<='B' and w.fixed != 'Y'
 and b.location = @location and 
	 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )
		
 update inv_list set std_util_dolrs=isnull( (select sum(b.std_util_dolrs * w.qty) 
	 from inv_list b, what_part w
	 where w.asm_no=inv_list.part_no and b.part_no=w.part_no and w.active<='B' and w.fixed != 'Y'
 and b.location = @location and 
	 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )




							-- mls 3/24/99 EPR d3 - 276

 
 update inv_list set std_cost = std_cost + isnull( (select sum(b.std_cost * w.qty / @eoq) 
	 from inv_list b, what_part w
	 where w.asm_no=inv_list.part_no and b.part_no=w.part_no and w.active<='B' and w.fixed = 'Y' 
 and b.location = @location and 
	 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )

 update inv_list set std_direct_dolrs= std_direct_dolrs + isnull( (select sum(b.std_direct_dolrs * w.qty / @eoq) 
	 from inv_list b, what_part w
	 where w.asm_no=inv_list.part_no and b.part_no=w.part_no and w.active<='B' and w.fixed = 'Y' 
 and b.location = @location and 
	 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )

 update inv_list set std_ovhd_dolrs = std_ovhd_dolrs + isnull( (select sum(b.std_ovhd_dolrs * w.qty / @eoq) 
	 from inv_list b, what_part w
	 where w.asm_no=inv_list.part_no and b.part_no=w.part_no and w.active<='B' and w.fixed = 'Y' 
 and b.location = @location and 
	 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )
		
 update inv_list set std_util_dolrs=std_util_dolrs + isnull( (select sum(b.std_util_dolrs * w.qty / @eoq) 
	 from inv_list b, what_part w
	 where w.asm_no=inv_list.part_no and b.part_no=w.part_no and w.active<='B' and w.fixed = 'Y' 
 and b.location = @location and 
 	 ( w.location = @location OR w.location = 'ALL' )), 0 )
 * @cst_pct						-- mls 3/24/99 EPR D3-276

	 where inv_list.part_no = @pn AND 		-- mls 3/24/99 EPR d3-276
		inv_list.location = @location AND
	 ( exists (select * from what_part where what_part.asm_no=inv_list.part_no) )




 END --Else 

 select @x=@x+1
-- mls 8/23/01 SCR 27412






 end
 select @x = 0
 update #tloc set status='Y' where tloc=@location
 select @y = count(*) from #tloc where status='N'
end


GO
GRANT EXECUTE ON  [dbo].[fs_costing] TO [public]
GO
