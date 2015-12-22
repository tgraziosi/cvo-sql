SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampurge_vwExists_sp] 
( 
	@company_id smallint, @date_purged char(8), @time_purged varchar(20),
	@valid int output 
) as 


DECLARE @dt	datetime
SELECT 	@dt = @date_purged + " " + @time_purged

if exists (select 1 
			from 	ampurge 
			WHERE 	company_id		= @company_id
			AND		date_created	= @dt
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampurge_vwExists_sp] TO [public]
GO
