SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_unrelease_sched_purchase]
	(
	@sched_item_id	INT
	)

AS
BEGIN
DECLARE	@resource_demand_id	INT,
	@uom_qty		DECIMAL(20,8),
	@qty			DECIMAL(20,8),
	@source_flag		CHAR(1)


BEGIN TRANSACTION


SELECT	@resource_demand_id=SP.resource_demand_id,
	@uom_qty=SI.uom_qty,
	@source_flag=SI.source_flag
FROM	dbo.sched_item SI,
	dbo.sched_purchase SP
WHERE	SI.sched_item_id = @sched_item_id
AND	SP.sched_item_id = @sched_item_id

IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	RETURN
	END


IF @source_flag	<> 'R'
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69312 'Can not unrelease a purchase order that has not been released'
	RETURN
	END


SELECT	@qty = RD.qty
FROM	dbo.resource_demand_group RD
WHERE	RD.row_id = @resource_demand_id

IF @@rowcount = 0
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69340 'Unable to find released purchase'
	RETURN
	END


IF @qty > @uom_qty
begin
	
	UPDATE	dbo.resource_demand_group
	SET	qty = qty - @uom_qty
	WHERE	row_id = @resource_demand_id

IF @@rowcount = 0
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69341 'Database Error: Unable to withdraw purchase order from purchasing'
	RETURN
	END

	delete from resource_demand
 	where batch_id = 'SCHEDULER' and parent = 'S' + convert(varchar(10),@sched_item_id)
end
ELSE
begin
	
	
	DELETE	dbo.resource_demand_group
	WHERE	row_id = @resource_demand_id

IF @@rowcount = 0
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69341 'Database Error: Unable to withdraw purchase order from purchasing'
	RETURN
	END

	DELETE resource_demand
	where batch_id = 'SCHEDULER' and group_no = convert(varchar(20),@resource_demand_id)
end


UPDATE	dbo.sched_item
SET	source_flag='P'
WHERE	sched_item_id = @sched_item_id


COMMIT TRANSACTION

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_unrelease_sched_purchase] TO [public]
GO
