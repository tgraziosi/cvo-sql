SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[cc_delete_comments_sp]	@comment_id varchar(8000)
AS

	EXEC('	DELETE cc_comments 
					WHERE	comment_id	IN ' + @comment_id )

GO
GRANT EXECUTE ON  [dbo].[cc_delete_comments_sp] TO [public]
GO
