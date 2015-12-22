SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			scm_pb_get_dw_rpt_new_scost_sp.sql
Type:			Stored Procedure
Called From:	Enterprise
Description:	Displays parts for Update Std Cost Utility
Developer:		Chris Tyler
Date:			6th April 2011

Revision History
v1.1	CT	06/04/11	New parameter 'Style'
*/


CREATE procedure [dbo].[scm_pb_get_dw_rpt_new_scost_sp] @cat varchar(10), @ptype varchar(10),
  @part varchar(30), @loc varchar(10), @org varchar(30), 
  @style varchar(40) -- v1.1

as
begin
  set nocount on

  SELECT c.timestamp,
         c.kys,   
         c.part_no,   
         c.cost_level,   
         c.new_type,   
         c.new_amt,   
         c.new_direction,   
         c.eff_date,   
         c.who_entered,   
         c.date_entered,   
         c.reason,   
         c.status,   
         c.note,   
         c.row_id,   
         m.description,   
         l.location,   
         l.avg_cost,   
         l.avg_direct_dolrs,   
         l.avg_ovhd_dolrs,   
         l.avg_util_dolrs,   
         l.std_cost,   
         l.std_direct_dolrs,   
         l.std_ovhd_dolrs,   
         l.std_util_dolrs,   
         m.category,   
         c.location,   
         space(1) _type1,   
         space(1) _type2,   
         space(1) _type3,   
         space(1) _type4,
         o1.organization_name
    FROM new_cost c
    join inv_master m (nolock) on m.part_no = c.part_no
    join inv_list l (nolock) on l.part_no = c.part_no and l.location = c.location
    join locations_all loc (nolock) on loc.location = c.location
    left outer join Organization_all o1 (nolock) on o1.organization_id = loc.organization_id
	INNER JOIN inv_master_add i (NOLOCK) ON m.part_no = i.part_no	-- v1.1
   WHERE ( c.status <= 'N' ) AND  
         ( isnull(m.category,'') like @cat ) AND  
         ( isnull(m.type_code,'') like @ptype ) AND  
         ( isnull(c.part_no,'') like @part ) and
         (( loc.organization_id like @org and @loc = '') or
		  ( c.location = @loc))
		 AND  (isnull(i.field_2,'') like @style ) -- v1.1

ORDER BY o1.organization_name, c.location, c.part_no, c.kys
end
GO
GRANT EXECUTE ON  [dbo].[scm_pb_get_dw_rpt_new_scost_sp] TO [public]
GO
