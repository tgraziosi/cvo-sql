SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

--  Copyright (c) 2000 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_resync_batch]
	(
	@debug_file	VARCHAR(255) = NULL
	)
AS
BEGIN

-- Create table to report differences -- this table will be populated by fs_compare_schedule

DECLARE	@sched_id INT,
	@object_flag		CHAR(1),
	@status_flag		CHAR(1),
	@location		VARCHAR(10),
	@resource_id		INT,
	@sched_resource_id	INT,
	@part_no		VARCHAR(30),
	@sched_order_id		INT,
	@order_no		INT,
	@order_ext		INT,
	@order_line		INT,
	@order_line_kit		INT,
	@sched_process_id	INT,
	@sched_operation_id	INT,	
	@prod_no		INT,
	@prod_ext		INT,
	@prod_line		INT,
	@sched_item_id		INT,
	@po_no			VARCHAR(10),
	@release_id		INT,
	@sched_transfer_id	INT,
	@transfer_id		INT,
	@transfer_line		INT,
	@resource_demand_id	INT,
        @forecast_demand_date   DATETIME,
        @forecast_qty           FLOAT,
        @forecast_uom           VARCHAR(2)

SET NOCOUNT ON

-- "Sync the Build plans"
EXECUTE fs_synchronize_resource


SELECT	@sched_id=MIN(SM.sched_id)
FROM	dbo.sched_model SM
WHERE	SM.batch_flag = 'B'

CREATE TABLE #result1								-- mls 1/22/03 SCR 30559
	(
	object_flag		CHAR(1),
	status_flag		CHAR(1),
	location		VARCHAR(10)	NULL,
	resource_id		INT		NULL,
	sched_resource_id	INT		NULL,
	part_no			VARCHAR(30)	NULL,
	sched_order_id		INT		NULL,
	order_no		INT		NULL,
	order_ext		INT		NULL,
	order_line		INT		NULL,
	order_line_kit		INT		NULL,
	sched_process_id	INT		NULL,
	sched_operation_id	INT		NULL,
	prod_no			INT		NULL,
	prod_ext		INT		NULL,
	prod_line		INT		NULL,
	sched_item_id		INT		NULL,
	po_no			VARCHAR(10)	NULL,
	release_id		INT		NULL,
	sched_transfer_id	INT		NULL,
	xfer_no			INT		NULL,
	xfer_line		INT		NULL,
	resource_demand_id	INT		NULL,
        forecast_demand_date    DATETIME        NULL,
        forecast_qty            FLOAT           NULL,
        forecast_uom            VARCHAR(2)      NULL,
	message			VARCHAR(255)	NULL,
        note			varchar(255)	NULL
	)

WHILE @sched_id IS NOT NULL
BEGIN
  insert #result1
  EXECUTE fs_compare_schedule @sched_id,'A',1				-- mls 1/22/03 SCR 30559

  Truncate table #result1

  
  SELECT @sched_id=MIN(SM.sched_id)
  FROM	dbo.sched_model SM
  WHERE	SM.batch_flag = 'B'
  AND	SM.sched_id > @sched_id
END

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_resync_batch] TO [public]
GO
