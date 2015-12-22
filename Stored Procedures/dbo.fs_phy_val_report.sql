SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_phy_val_report] @phy_id int, @costmeth char(1) AS 

create table #tphy ( phy_batch int, location varchar(10), part_no varchar(30), 
                     orig_qty decimal(20,8), qty decimal(20,8),
                     cost decimal(20,8), description varchar(255) NULL )
INSERT #tphy
SELECT phy_batch, location, part_no, sum(orig_qty), sum(qty), 
       0, null
FROM   physical
WHERE  phy_batch = @phy_id
GROUP BY phy_batch, location, part_no
ORDER BY phy_batch, location, part_no
if @costmeth = 'A' begin
   UPDATE #tphy
   SET cost = (i.avg_cost+i.avg_direct_dolrs+i.avg_ovhd_dolrs+i.avg_util_dolrs),
       description = i.description
   FROM   inventory i
   WHERE  #tphy.part_no = i.part_no and #tphy.location = i.location
end
if @costmeth = 'S' begin
   UPDATE #tphy
   SET cost = (i.std_cost+i.std_direct_dolrs+i.std_ovhd_dolrs+i.std_util_dolrs),
       description = i.description
   FROM   inventory i

   WHERE  #tphy.part_no = i.part_no and #tphy.location = i.location
end

SELECT location, part_no, orig_qty, qty, 
       cost, @costmeth 'c_meth', description, phy_batch
FROM   #tphy
ORDER BY orig_qty*cost DESC, part_no



GO
GRANT EXECUTE ON  [dbo].[fs_phy_val_report] TO [public]
GO
