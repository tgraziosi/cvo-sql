SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[EAI_process_insert]
	(
	@vb_script		VARCHAR(100),
	@data			VARCHAR(500) = null,
	@source_platform	VARCHAR(100),
	@action			INT = 0,
	@deleted_flag		VARCHAR(1) = 'N'
	)
AS
BEGIN
/* the procedure returns 1 if unsuccessful, 0 if successful */

	if exists (select 'X' from EAI_process (NOLOCK)
		   		where vb_script = @vb_script and 
				data = @data and
				source_platform = @source_platform and
				action = @action) 
	   begin	     	
			if (@vb_script <> 'PartPrice' AND @vb_script <> 'PurProdRequest')
			update EAI_process set entered_time = GetDate()
		   		where vb_script = @vb_script and 
				data = @data and
				source_platform = @source_platform and
				action = @action
	     	else
			update EAI_process set entered_time = DateAdd(mi, 1, GetDate()) 
				where vb_script = @vb_script and 
				data = @data and
				source_platform = @source_platform and
				action = @action

	     	return 0	-- assume that the order is already in the queue to be processed
	   end
	else
	   begin
		if (IsNull(@vb_script,'') = '')
		   return 1

		if (IsNull(@source_platform,'') = '')
		   return 1

		insert EAI_process(vb_script, data, source_platform, action, deleted_flag)
		VALUES (@vb_script, @data, @source_platform, @action, @deleted_flag)
		
		if (@vb_script = 'PartPrice' OR @vb_script = 'PurProdRequest')
			update EAI_process set entered_time = DateAdd(mi, 1, GetDate()) 
				where vb_script = @vb_script and 
				data = @data and
				source_platform = @source_platform and
				action = @action
		return 0
	   end				
return 0
END

GO
GRANT EXECUTE ON  [dbo].[EAI_process_insert] TO [public]
GO
