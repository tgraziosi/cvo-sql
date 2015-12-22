SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_comments_i_sp]
	@sequence_id	int,
	@customer_code	varchar(20),
	@user_name	varchar(20),
	@date varchar(30),
	@comment	varchar(255),
	@comment_id	int OUTPUT,
	@log_type	tinyint = NULL,
	@doc_ctrl_num varchar(16) = NULL,
	@org_comment_id int = NULL,
	@org_user_name varchar(20) = NULL,
	@from_alerts smallint = 0

AS



SET NOCOUNT ON

DECLARE @date_time	datetime

SELECT @date_time = GETDATE()

IF ( @org_comment_id IS NULL OR @org_comment_id = 0 ) 
	BEGIN
		SELECT @comment_id = ISNULL(MAX(comment_id), 0) + 1 FROM cc_comments
		INSERT cc_comments 
		SELECT	@comment_id,
			@sequence_id, 
			@customer_code, 
			@user_name, 
			@date_time, 
			@comment,
			@log_type,
			@doc_ctrl_num,
			NULL,
			NULL,
			@from_alerts

		SELECT @comment_id

	END
ELSE
	BEGIN

		DELETE cc_comments
		WHERE comment_id = @org_comment_id
		AND	row_num >= @sequence_id

		
		INSERT cc_comments 	(	comment_id, 
													row_num,	
													customer_code,	
													[user_name],	
													comment_date,	
													comments,	
													log_type, 
													doc_ctrl_num,	
													updated_user_name,	
													updated_comment_date, 
													from_alerts)
		SELECT	@org_comment_id,
			@sequence_id, 
			@customer_code, 
			@org_user_name,
			@date,
			@comment,
			@log_type,
			@doc_ctrl_num,
			@user_name, 
			@date_time,
			@from_alerts
		END

SET NOCOUNT ON

GO
GRANT EXECUTE ON  [dbo].[cc_comments_i_sp] TO [public]
GO
