SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_explode_cost] @pn1 varchar(30), @loc varchar(10), @org varchar(30)  AS
set nocount on

-- mls 10/1/02 SCR 29826 - changed to explode the same part at different levels

select @loc = isnull(@loc,'')
select @org = isnull(@org,'')

if @org != '' select @loc = ''


declare @lev int, @x int
declare @pn2 varchar(30), @msg varchar(50)
select @lev = 1
select @x = 0



CREATE TABLE #tbuild 
( assy varchar(30),
  status char(1) NULL,
  ilevel int )

create index t1 on #tbuild (status,assy,ilevel)

INSERT #tbuild SELECT @pn1, 
  case when exists( select 1 FROM what_part w, inv_master m 
    WHERE w.part_no = @pn1 and w.asm_no = m.part_no and m.status < 'N') then 'Y' else 'X' end, 0 -- mls 11/22/02 SCR 30162

select @x = count(*) FROM #tbuild WHERE status = 'Y'
while @x > 0
begin
   SELECT @lev = @lev + 1

   INSERT #tbuild 
     SELECT distinct w.asm_no, 'N', @lev
      FROM   what_part w, #tbuild t, inv_master m			-- mls 11/22/02 SCR 30162
      WHERE  w.part_no  =  t.assy AND
             w.active   <= 'B'  AND 
             t.status =  'Y' AND
             w.asm_no = m.part_no and m.status < 'N'

   UPDATE #tbuild set status='X' WHERE status='Y'

   UPDATE #tbuild
      set status='Y'
      WHERE exists( select 1 FROM what_part w, inv_master m 
        WHERE w.part_no = @pn1 and w.asm_no = m.part_no and m.status < 'N') AND status='N'	-- mls 11/22/02 SCR 30162

   UPDATE #tbuild set status='X' WHERE status='N'

   SELECT @x = count(*) FROM #tbuild WHERE status = 'Y'
END

insert #tbuild
select assy, 'A', max(ilevel)
from #tbuild
where status < 'Z'
group by assy

update t									-- mls 02/25/03 SCR 30764 start
set status = 'Z'	
from #tbuild t, inv_master m
where t.assy = m.part_no and t.status = 'A' and t.assy = @pn1 and ilevel = 0
and m.status > 'M'								-- mls 02/25/03 SCR 30764 end

SELECT @x = count(*) FROM #tbuild WHERE status = 'A'
while @x > 0
BEGIN
   SET ROWCOUNT 1
   SELECT @pn2 = assy, @lev = ilevel 						-- mls 10/01/02 SCR 29826
     FROM #tbuild WHERE status = 'A' ORDER BY ilevel			
   SET ROWCOUNT 0

   exec fs_costing @pn2, @org, @loc

   UPDATE #tbuild set status='Z' WHERE status = 'A' and assy=@pn2 and ilevel = @lev	-- mls 10/01/02 SCR 29826

   SELECT @x = count(*) FROM #tbuild WHERE status = 'A'
END

GO
GRANT EXECUTE ON  [dbo].[fs_explode_cost] TO [public]
GO
