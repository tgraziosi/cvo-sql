SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_prod_anal_2] @loc varchar(10),@comppn varchar(30),@bdate datetime,
@edate datetime,@variance money   AS

  if @comppn <> '%' 
    BEGIN
      SELECT p.part_no, p.part_no,   
             dbo.inventory.description,
             sum(dbo.prod_list.plan_qty),   
             sum(dbo.prod_list.used_qty),
             @comppn,@bdate,@edate,@variance,0    
        FROM dbo.prod_list,   
             dbo.inventory,
             dbo.produce_all p  
       WHERE ( p.part_no = dbo.inventory.part_no ) and  
             ( p.location = dbo.inventory.location ) and
             ( dbo.prod_list.prod_no = p.prod_no ) and
             ( dbo.prod_list.prod_ext = p.prod_ext ) and
             ( p.prod_date >= @bdate and p.prod_date <= @edate) and
             ( dbo.prod_list.part_no = @comppn and dbo.prod_list.direction < 0 )
    GROUP BY p.part_no,dbo.inventory.description
    HAVING ( sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) - 1.0 >= @variance ) OR
           ( sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) - 1.0 <= ( (-1) * @variance ) )
    ORDER BY sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) desc
   END
GO
GRANT EXECUTE ON  [dbo].[fs_prod_anal_2] TO [public]
GO
