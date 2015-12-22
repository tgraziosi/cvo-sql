SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_release_inventory]
	(
	@sched_item_id		INT=NULL,
	@sched_process_id	INT=NULL
	)

AS
BEGIN
DECLARE	@source_flag	CHAR(1)


CREATE TABLE #remove(sched_item_id INT)

IF @sched_item_id IS NOT NULL
	INSERT	#remove(sched_item_id)
	VALUES	(@sched_item_id)


SELECT	@sched_item_id=MIN(R.sched_item_id)
FROM	#remove R


WHILE @sched_item_id IS NOT NULL AND @sched_process_id IS NOT NULL
	BEGIN
	IF @sched_process_id IS NOT NULL
		BEGIN
		
		DELETE	#remove
		FROM	dbo.sched_item SI,
			#remove R
		WHERE	SI.sched_process_id = @sched_process_id
		AND	R.sched_item_id = SI.sched_item_id

		
		IF NOT EXISTS(SELECT * FROM dbo.sched_item SI,dbo.sched_order_item SOI WHERE SI.sched_process_id = @sched_process_id AND SOI.sched_item_id = SI.sched_item_id)
			IF NOT EXISTS(SELECT * FROM dbo.sched_item SI,dbo.sched_operation_item SOI WHERE SI.sched_process_id = @sched_process_id AND SOI.sched_item_id = SI.sched_item_id)
				IF NOT EXISTS(SELECT * FROM dbo.sched_item SI,dbo.sched_transfer_item STI WHERE SI.sched_process_id = @sched_process_id AND STI.sched_item_id = SI.sched_item_id)
					BEGIN
					
					INSERT	#remove(sched_item_id)
					SELECT	SOI.sched_item_id
					FROM	dbo.sched_item SI,
						dbo.sched_operation SO,
						dbo.sched_operation_item SOI
					WHERE	SI.sched_item_id = @sched_item_id
					AND	SO.sched_process_id = SI.sched_process_id
					AND	SOI.sched_operation_id = SO.sched_operation_id

					
					IF (SELECT SP.source_flag FROM dbo.sched_process SP WHERE SP.sched_process_id = @sched_process_id) = 'P'
						BEGIN
						
						DELETE	dbo.sched_process
						FROM	dbo.sched_process SP
						WHERE	SP.sched_process_id = @sched_process_id
						END

					
					ELSE	BEGIN
						
						DELETE	dbo.sched_item
						FROM	dbo.sched_item SI
						WHERE	SI.sched_process_id = @sched_process_id

						
						DELETE	dbo.sched_operation_item
						FROM	dbo.sched_operation SO,
							dbo.sched_operation_item SOI
						WHERE	SO.sched_process_id = @sched_process_id
						AND	SO.operation_status <> 'L'
						AND	SOI.sched_operation_id = SO.sched_operation_id

						
						DELETE	dbo.sched_operation_resource
						FROM	dbo.sched_operation SO,
							dbo.sched_operation_resource SOR
						WHERE	SO.sched_process_id = @sched_process_id
						AND	SO.operation_status <> 'L'
						AND	SOR.sched_operation_id = SO.sched_operation_id

						
						UPDATE	dbo.sched_operation
						SET	operation_status='U',
							work_datetime=NULL,
							done_datetime=NULL
						FROM	dbo.sched_operation SO
						WHERE	SO.sched_process_id = @sched_process_id
						AND	SO.operation_status <> 'L'
						END
					END

		
		SELECT	@sched_process_id = NULL
		END

	
	ELSE	BEGIN
		
		SELECT	@source_flag=SI.source_flag,
			@sched_process_id=SI.sched_process_id
		FROM	dbo.sched_item	SI
		WHERE	SI.sched_item_id = @sched_item_id

		
		IF @source_flag = 'M'
			CONTINUE

		
		IF @source_flag = 'P'
			
			IF NOT EXISTS(SELECT * FROM dbo.sched_order_item SOI WHERE SOI.sched_item_id = @sched_item_id)
				IF NOT EXISTS(SELECT * FROM dbo.sched_operation_item SOI WHERE SOI.sched_item_id = @sched_item_id)
					IF NOT EXISTS(SELECT * FROM dbo.sched_transfer_item STI WHERE STI.sched_item_id = @sched_item_id)
						BEGIN
						DELETE	dbo.sched_item
						FROM	dbo.sched_item SI
						WHERE	SI.sched_item_id = @sched_item_id
						END

		
		DELETE	#remove
		FROM	#remove R
		WHERE	R.sched_item_id = @sched_item_id
		END

	
	SELECT	@sched_item_id=MIN(R.sched_item_id)
	FROM	#remove R
	END

DROP TABLE #remove
RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_release_inventory] TO [public]
GO
