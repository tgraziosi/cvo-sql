SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_prod_anl] @loc varchar(10),@assypn varchar(30),@bdate datetime,
@edate datetime,@variance money AS

  if @assypn = '%'
    BEGIN
     SELECT  dbo.prod_list.part_no, dbo.prod_list.part_no,  
             dbo.inventory.description,
             sum(dbo.prod_list.plan_qty),   
             sum(dbo.prod_list.used_qty),
             @assypn,@bdate,@edate,@variance,0 
        FROM dbo.prod_list,   
             dbo.inventory,
             produce_all p
       WHERE ( dbo.prod_list.part_no = dbo.inventory.part_no ) and  
             ( dbo.prod_list.location = dbo.inventory.location ) and
             ( dbo.prod_list.prod_no = p.prod_no ) and
             ( dbo.prod_list.prod_ext = p.prod_ext ) and
             ( p.status > 'Q' and p.status < 'V' ) and
             ( dbo.prod_list.direction < 0 ) and
             ( p.prod_date >= @bdate and p.prod_date <= @edate) and
             ( dbo.prod_list.constrain != 'C')						-- mls 8/29/03 SCR 31816
    GROUP BY dbo.prod_list.part_no,dbo.inventory.description
      HAVING ( sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) - 1.0 >= @variance ) OR
             ( sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) - 1.0 <= ( (-1) * @variance ) )
    ORDER BY sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) desc
   END
  if @assypn <> '%' 
    BEGIN
      SELECT dbo.prod_list.part_no, dbo.prod_list.part_no,   
             dbo.inventory.description,
             sum(dbo.prod_list.plan_qty),   
             sum(dbo.prod_list.used_qty),
             @assypn,@bdate,@edate,@variance,0    
        FROM dbo.prod_list,   
             dbo.inventory,
             produce_all p  
       WHERE ( dbo.prod_list.part_no = dbo.inventory.part_no ) and  
             ( dbo.prod_list.location = dbo.inventory.location ) and
             ( dbo.prod_list.prod_no = p.prod_no ) and
             ( dbo.prod_list.prod_ext = p.prod_ext ) and
             ( p.status > 'Q' and p.status < 'V' ) and
             ( dbo.prod_list.direction < 0 ) and
             ( p.prod_date >= @bdate and p.prod_date <= @edate) and
             ( p.part_no = @assypn ) and
             ( dbo.prod_list.constrain != 'C')						-- mls 8/29/03 SCR 31816
    GROUP BY dbo.prod_list.part_no,dbo.inventory.description
    HAVING ( sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) - 1.0 >= @variance ) OR
           ( sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) - 1.0 <= ( (-1) * @variance ) )
    ORDER BY sum(dbo.prod_list.used_qty)/sum(dbo.prod_list.plan_qty) desc
   END
GO
GRANT EXECUTE ON  [dbo].[fs_prod_anl] TO [public]
GO
