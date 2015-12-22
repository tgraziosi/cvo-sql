SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE proc [dbo].[cc_user_zoom_sp] @type smallint = 0,
														@text varchar(45) = '',
														@direction smallint = 0
AS

	SET rowcount 50


	IF ( @type = 0 )
		BEGIN
			IF @direction = 0
				SELECT 'User ID' = [user_id], 'User Name' = [user_name] 
				FROM CVO_Control..smusers 
				WHERE [user_id] >= @text
				ORDER BY [user_id]
			IF @direction = 1
				SELECT 'User ID' = [user_id], 'User Name' = [user_name] 
				FROM CVO_Control..smusers 
				WHERE [user_id] <= @text
				ORDER BY [user_id] DESC
			IF @direction = 2
				SELECT 'User ID' = [user_id], 'User Name' = [user_name] 
				FROM CVO_Control..smusers 
				WHERE [user_id] >= @text
				ORDER BY [user_id] ASC
		END
	ELSE
		BEGIN
			IF @direction = 0
				SELECT 'User Name' = [user_name], 'User ID' = [user_id]
				FROM CVO_Control..smusers 
				WHERE [user_name] >= @text
				ORDER BY [user_name]
			IF @direction = 1
				SELECT 'User Name' = [user_name], 'User ID' = [user_id]
				FROM CVO_Control..smusers 
				WHERE [user_name] <= @text
				ORDER BY [user_name] DESC
			IF @direction = 2
				SELECT 'User Name' = [user_name], 'User ID' = [user_id]
				FROM CVO_Control..smusers 
				WHERE [user_name] >= @text
				ORDER BY [user_name] ASC
		END

		

SET rowcount 0
GO
GRANT EXECUTE ON  [dbo].[cc_user_zoom_sp] TO [public]
GO
