SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[get_i_uom] @part_no varchar(255), @username varchar(10)='' AS



  SELECT u.item,   
         u.std_uom,   
         u.alt_uom,   
         u.conv_factor
    FROM dbo.uom_table u
    left outer join dbo.inv_master i (nolock) on i.part_no = u.item          
   WHERE (u.item = @part_no or u.item = 'STD') 



ORDER BY u.std_uom asc, u.conv_factor asc

GO
GRANT EXECUTE ON  [dbo].[get_i_uom] TO [public]
GO
