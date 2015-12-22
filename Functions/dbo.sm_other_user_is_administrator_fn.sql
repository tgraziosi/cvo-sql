SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE  FUNCTION [dbo].[sm_other_user_is_administrator_fn] ( @testname varchar(30) )
	RETURNS smallint
AS
	BEGIN 
		DECLARE @is_admin SMALLINT
		SELECT @is_admin =0
			
		SELECT @is_admin=COUNT(DISTINCT global_flag) FROM CVO_Control..smgrphdr h
		  INNER JOIN smgrpdet_vw d
			  ON h.group_id = d.group_id
			  AND d.domain_username = @testname
			  AND ISNULL(h.global_flag,0)=1

		RETURN @is_admin
	END
	
GO
GRANT REFERENCES ON  [dbo].[sm_other_user_is_administrator_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_other_user_is_administrator_fn] TO [public]
GO
