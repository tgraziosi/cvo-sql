SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_update_events_sp]		@contract_ctrl_num		VARCHAR(16),
																				@sequence_id					INT,
																				@void_flag						INT
	

AS

	DECLARE 	@result			INT,
						@today			INT,
						@userid			INT				
						
	SELECT	@today = DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906


/*
	SELECT 		@userid = [user_id]
	FROM			CVO_Control..smusers
	WHERE			[user_name] = SUSER_SNAME()
*/

	BEGIN TRAN

		UPDATE	pr_events
		SET 		void_flag = @void_flag
		WHERE		contract_ctrl_num = @contract_ctrl_num
		AND			sequence_id = @sequence_id	
		
		IF @@ERROR <> 0
			BEGIN
				ROLLBACK TRAN
				RETURN @@ERROR
			END


	COMMIT TRAN

GO
GRANT EXECUTE ON  [dbo].[pr_update_events_sp] TO [public]
GO
