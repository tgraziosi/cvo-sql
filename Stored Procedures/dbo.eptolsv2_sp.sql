SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[eptolsv2_sp] @tolerance_code char(8) ,
								@tolerance_type int 

AS 
 update #eptoltp1
 set tolerance_basis 	= 	eptoltp2.tolerance_basis,
							basis_value 	 	= 	eptoltp2.basis_value,
							over_flag 	= 	eptoltp2.over_flag,
							under_flag 	 	 	= 	eptoltp2.under_flag,
							display_msg_flag	= eptoltp2.display_msg_flag,
							message				= 	eptoltp2.message, 
							active_flag = 1
 from #eptoltp2 eptoltp2
	where #eptoltp1.tolerance_code = @tolerance_code
 and eptoltp2.tolerance_code = @tolerance_code
 and eptoltp2.tolerance_type = @tolerance_type
 and #eptoltp1.tolerance_type = @tolerance_type
 IF @@error != 0
		RETURN -1

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[eptolsv2_sp] TO [public]
GO
