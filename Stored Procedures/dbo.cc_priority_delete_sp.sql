SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_priority_delete_sp]
	@priority_code varchar(8)
AS
delete from cc_priority_codes
	where priority_code = @priority_code
 
GO
GRANT EXECUTE ON  [dbo].[cc_priority_delete_sp] TO [public]
GO
