SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_create_schedule]
	(
	@sched_id	INT OUT,
	@sched_name	VARCHAR(16) = NULL OUT,
        @wrap_call      INT = 0					-- mls 7/9/01 SCR 27161
	)
AS
BEGIN

DECLARE	@rowcount		INT,
	@seek_name		VARCHAR(16),
	@seek_index		INT


BEGIN TRANSACTION


IF @sched_name IS NULL OR @sched_name = ''
	
	SELECT	@sched_name = 'New Model'


SELECT	@seek_name=@sched_name,
	@seek_index=1

WHILE EXISTS (SELECT * FROM dbo.sched_model SM (TABLOCKX) WHERE SM.sched_name = @seek_name)
	BEGIN
	SELECT	@seek_index = @seek_index+1
	SELECT	@seek_name  = @sched_name + ' ('+CONVERT(VARCHAR(8),@seek_index)+')'
	END


SELECT	@sched_name = @seek_name


INSERT INTO dbo.sched_model(sched_name)
VALUES	(@sched_name)


SELECT	@sched_id = @@Identity,
	@rowcount = @@RowCount


IF @rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	if @wrap_call = 0							-- mls 7/9/01 SCR 27161
	RaisError 69040 'Problem creating new schedule encountered.'
	RETURN 69040								-- mls 7/9/01 SCR 27161
	END

COMMIT TRANSACTION
RETURN 1									-- mls 7/9/01 SCR 27161
END
GO
GRANT EXECUTE ON  [dbo].[fs_create_schedule] TO [public]
GO
