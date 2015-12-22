SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[eptoltp1_sp] @tolerance_code char(8), 
 @load_flag smallint 
AS 

delete #eptoltp1
IF @@error != 0
		RETURN -1

if @load_flag = 0
 insert #eptoltp1 (tolerance_code, tolerance_type, tolerance_type_desc,
 active_flag, 
 tolerance_basis, basis_value, over_flag, under_flag,
 display_msg_flag, message )
 select @tolerance_code, tolerance_type, tolerance_type_desc,
 0, 
 0, 0, 0, 0,
 0, ""
 from eptoltyp
 IF @@error != 0
		RETURN -1
else 
 insert #eptoltp1 (tolerance_code, tolerance_type, tolerance_type_desc,
 active_flag, 
 tolerance_basis, basis_value, over_flag, under_flag,
 display_msg_flag, message )
 select @tolerance_code, eptollin.tolerance_type, tolerance_type_desc,
 active_flag, 
 tolerance_basis, basis_value, over_flag, under_flag,
 display_msg_flag, message
 from eptollin, eptoltyp
 where eptollin.tolerance_code = @tolerance_code
 and eptollin.tolerance_type = eptoltyp.tolerance_type
 IF @@error != 0
		RETURN -1

	update #eptoltp1
 set tolerance_basis = 3
	where #eptoltp1.active_flag = 0
	IF @@error != 0
		RETURN -1

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[eptoltp1_sp] TO [public]
GO
