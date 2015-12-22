SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_manager_status] 
	@userName varchar(30)

AS
select manager from CVO_Control..smusers where user_name = @userName

GO
GRANT EXECUTE ON  [dbo].[cc_get_manager_status] TO [public]
GO
