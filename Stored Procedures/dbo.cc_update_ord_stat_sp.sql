SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_update_ord_stat_sp] 	@status_code	varchar(5),
																				@use_flag	int = 0, 
																				@include_returns smallint = 0

AS

	UPDATE	cc_ord_status 
	SET 	use_flag = @use_flag,
				include_credit_returns = @include_returns
	WHERE	status_code = @status_code
	
GO
GRANT EXECUTE ON  [dbo].[cc_update_ord_stat_sp] TO [public]
GO
