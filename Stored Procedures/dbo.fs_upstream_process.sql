SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
-- mls 7/17/01  SCR 27221 changed to return source flag

CREATE PROCEDURE [dbo].[fs_upstream_process]
	(
	@sched_order_id	INT=NULL,
	@sched_item_id	INT=NULL
	)
AS
BEGIN
DECLARE	@rowcount		INT,
	@hierarchy_level	INT,
	@source_flag		CHAR(1),
	@prod_no		INT,
	@prod_ext		INT


SELECT	@rowcount=0,
	@hierarchy_level=1


CREATE TABLE #result
	(
	sched_process_id	INT,
	hierarchy_level		INT
	)

CREATE UNIQUE CLUSTERED INDEX result ON #result(sched_process_id)


IF @sched_order_id IS NOT NULL
	BEGIN
	
	SELECT	@source_flag=SO.source_flag,
		@prod_no=SO.prod_no,
		@prod_ext=SO.prod_ext
	FROM	dbo.sched_order SO
	WHERE	SO.sched_order_id = @sched_order_id

	
	IF @source_flag <> 'J'
		BEGIN
		INSERT INTO #result(sched_process_id,hierarchy_level)
		SELECT	DISTINCT
			SI.sched_process_id,@hierarchy_level
		FROM	dbo.sched_item SI,
			dbo.sched_order_item SOI
		WHERE	SOI.sched_order_id = @sched_order_id
		AND	SI.sched_item_id = SOI.sched_item_id
		AND	SI.sched_process_id IS NOT NULL

		
		SELECT	@rowcount=@@rowcount
		END
	ELSE 
		BEGIN
		INSERT INTO #result(sched_process_id,hierarchy_level)
		SELECT	DISTINCT
			SP.sched_process_id,@hierarchy_level
		FROM	dbo.sched_process SP
		WHERE	SP.prod_no = @prod_no
		AND	SP.prod_ext = @prod_ext

		
		SELECT	@rowcount=@@rowcount
		END

	END
ELSE IF @sched_item_id IS NOT NULL
	BEGIN
	INSERT INTO #result(sched_process_id,hierarchy_level)
	SELECT	DISTINCT
		SI.sched_process_id,@hierarchy_level
	FROM	dbo.sched_item SI
	WHERE	SI.sched_item_id = @sched_item_id
	AND	SI.sched_process_id IS NOT NULL

	
	SELECT	@rowcount=@@rowcount

	END


WHILE @rowcount > 0
	BEGIN
	
	INSERT INTO #result(sched_process_id,hierarchy_level)
	SELECT	DISTINCT
		SI.sched_process_id,@hierarchy_level+1
	FROM	#result R,
		dbo.sched_operation SO,
		dbo.sched_operation_item SOI,
		dbo.sched_item SI
	WHERE	R.hierarchy_level = @hierarchy_level
	AND	SO.sched_process_id = R.sched_process_id
	AND	SOI.sched_operation_id = SO.sched_operation_id
	AND	SI.sched_item_id = SOI.sched_item_id
	AND	SI.sched_process_id IS NOT NULL
	AND NOT EXISTS (SELECT	*
			FROM	#result R2
			WHERE	R2.sched_process_id = SI.sched_process_id)

	
	SELECT	@rowcount=@@rowcount,
		@hierarchy_level=@hierarchy_level+1
	END


SELECT	SP.sched_process_id,
	R.hierarchy_level,
	SP.prod_no,
	SP.prod_ext,
	SPP.part_no,	
	(SELECT IM.description FROM dbo.inv_master IM WHERE IM.part_no = SPP.part_no),	
	(SELECT MIN(SO.work_datetime) FROM dbo.sched_operation SO WHERE SO.sched_process_id = SP.sched_process_id),	
	(SELECT MAX(SO.done_datetime) FROM dbo.sched_operation SO WHERE SO.sched_process_id = SP.sched_process_id),	
        SP.source_flag									-- mls 7/17/01 SCR 27221
FROM	#result R
join	dbo.sched_process SP (nolock) on SP.sched_process_id = R.sched_process_id
left outer join dbo.sched_process_product SPP (nolock) on SPP.sched_process_id = R.sched_process_id AND SPP.usage_flag = 'P'



DROP TABLE #result

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_upstream_process] TO [public]
GO
