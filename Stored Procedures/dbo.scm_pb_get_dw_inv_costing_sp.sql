SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[scm_pb_get_dw_inv_costing_sp] @part varchar(30) as
begin
  set nocount on

  SELECT c.tran_no,   
         c.tran_ext,   
         c.part_no,   
         c.location,   
         c.tran_date,   
         c.quantity,   
         c.balance,   
         c.unit_cost,   
         c.direct_dolrs,   
         c.ovhd_dolrs,   
         c.util_dolrs,   
         c.sequence,   
         c.tran_code,   
         c.tran_line,   
         c.tran_age,   
         c.labor,   
         c.account,   
         c.org_cost,   
         c.unit_cost _unit_cost,   
         c.direct_dolrs _direct_dolrs,   
         c.ovhd_dolrs _ovhd_dolrs,   
         c.util_dolrs _util_dolrs,   
         ' ' _method,   
         case when m.inv_cost_method = 'E' then c.lot_ser  else '' end _lot_ser,
         m.inv_cost_method,
		 o1.organization_name org_name
    FROM inv_costing c
    join inv_master m (nolock) on m.part_no = c.part_no
	join locations l (nolock) on l.location = c.location
    left outer join Organization_all o1 (nolock) on o1.organization_id = l.organization_id
   WHERE c.part_no = @part
  ORDER BY org_name ASC, c.location ASC, c.lot_ser ASC, c.tran_date ASC, c.tran_no ASC, c.tran_ext ASC   
end
GO
GRANT EXECUTE ON  [dbo].[scm_pb_get_dw_inv_costing_sp] TO [public]
GO
