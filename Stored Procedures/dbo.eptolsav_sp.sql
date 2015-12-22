SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[eptolsav_sp] @match_type	smallint
AS 
declare @tolerance_code char(8) 
 
SELECT @tolerance_code = ""
SELECT @tolerance_code = tolerance_code
FROM #eptoltp1
 
IF (NOT EXISTS (	SELECT	*
 				FROM	eptolhdr
 				WHERE	tolerance_code = @tolerance_code
 			 ))
BEGIN 
	insert eptolhdr (timestamp,
					 tolerance_code, 
					 matching_type )
 	VALUES( NULL,
 					@tolerance_code, 
 					@match_type)
 IF @@error != 0
		RETURN -1	
END

 insert eptollin (tolerance_code, 
 					tolerance_type, 
 					active_flag, 
 tolerance_basis, 
 basis_value, 
 over_flag, 
 under_flag,
 display_msg_flag, 
 message )
 select tolerance_code, 
 				 tolerance_type, 
 				 active_flag, 
 tolerance_basis, 
 basis_value, 
 over_flag, 
 under_flag,
 display_msg_flag, 
 message
 from #eptoltp1
 IF @@error != 0
		RETURN -1 


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[eptolsav_sp] TO [public]
GO
