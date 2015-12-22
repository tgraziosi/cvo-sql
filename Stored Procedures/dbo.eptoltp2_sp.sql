SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[eptoltp2_sp] @tolerance_code char(9),
								@tolerance_type int,
 @load_flag smallint 
AS 

delete #eptoltp2
IF @@error != 0
		RETURN -1

if @load_flag = 0
BEGIN
 insert #eptoltp2 ( tolerance_code, tolerance_type,
							tolerance_basis, basis_value, over_flag, under_flag,
 display_msg_flag, message )
 select @tolerance_code, @tolerance_type,
							3, 0, 1, 1,
							0, ""
 IF @@error != 0
		RETURN -1	
END

else
BEGIN 
 insert #eptoltp2 ( tolerance_code, tolerance_type, 
 tolerance_basis, basis_value, over_flag, under_flag,
 display_msg_flag, message )
 select @tolerance_code, @tolerance_type, 
 tolerance_basis, basis_value, over_flag, under_flag,
 display_msg_flag, message
 from #eptoltp1 eptoltp1
 where eptoltp1.tolerance_code = @tolerance_code
 and eptoltp1.tolerance_type = @tolerance_type
 IF @@error != 0
		RETURN -1 
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[eptoltp2_sp] TO [public]
GO
