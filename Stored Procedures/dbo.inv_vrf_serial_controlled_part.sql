SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[inv_vrf_serial_controlled_part] @c_part_no varchar(30) AS
BEGIN --Start proc

-- All this is doing is returning a 1 if the part is serial controlled or a 0 if is not.

return (select serial_flag from inv_master where part_no = @c_part_no)

END -- End proc






/**/
GO
GRANT EXECUTE ON  [dbo].[inv_vrf_serial_controlled_part] TO [public]
GO
