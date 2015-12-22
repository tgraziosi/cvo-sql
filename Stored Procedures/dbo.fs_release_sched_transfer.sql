SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_release_sched_transfer]
	(
	@sched_transfer_id	INT,
	@who		VARCHAR(20)=NULL
	)

AS
BEGIN

DECLARE	@source_flag	CHAR(1),
	@beg_location	VARCHAR(10),
	@end_location	VARCHAR(10),
	@end_datetime	DATETIME,
	@beg_datetime	DATETIME,
	@transfer_id	INT,
	@transfer_line	INT






IF @who IS NULL
	SELECT	@who='SCHEDULER'
ELSE IF NOT EXISTS (SELECT * FROM dbo.ewusers_vw SU WHERE SU.user_name = @who)				-- mls 5/30/00
	BEGIN
	RaisError 60110 'The user specified does not exist in millenia.'
	RETURN
	END

BEGIN TRANSACTION






SELECT	@beg_location=ST.location,
	@beg_datetime=ST.move_datetime,
	@source_flag=ST.source_flag
FROM	dbo.sched_transfer ST (TABLOCKX)
WHERE	ST.sched_transfer_id = @sched_transfer_id


IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69410 'The scheduled transfer could not be found'
	RETURN
	END


IF @source_flag = 'R'
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69440 'This transfer has already been released'
	RETURN
	END


SELECT	@end_location=SI.location
FROM	dbo.sched_item SI
WHERE	SI.sched_transfer_id = @sched_transfer_id
AND	SI.source_flag = 'X'


IF @@rowcount = 0
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69441 'No items have been defined for this transfer'
	RETURN
	END


IF EXISTS (SELECT * FROM dbo.sched_item SI WHERE SI.sched_transfer_id = @sched_transfer_id AND SI.source_flag = 'X' AND SI.location <> @end_location)
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69433 'Multi-destination transfers are not currently supported and can not be released to Millenia.'
	RETURN
	END


SELECT	@end_datetime=MIN(SI.done_datetime)
FROM	dbo.sched_item SI
WHERE	SI.sched_transfer_id = @sched_transfer_id
AND	SI.source_flag = 'X'






SELECT	@transfer_id=NXN.last_no+1
FROM	dbo.next_xfer_no NXN (TABLOCKX)

IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69449 'Next transfer number could not be found.'
	RETURN
	END

INSERT	dbo.xfers_all
	(
	xfer_no,	
	from_loc,	
	to_loc,		
	req_ship_date,	
	sch_ship_date,	
	date_shipped,	
	date_entered,	
	req_no,		
	who_entered,	
	status,		
	attention,	
	phone,		
	routing,	
	special_instr,	
	fob,		
	freight,	
	printed,	
	label_no,	
	no_cartons,	
	who_shipped,	
	date_printed,	
	who_picked,	
	to_loc_name,	
	to_loc_addr1,	
	to_loc_addr2,	
	to_loc_addr3,	
	to_loc_addr4,	
	to_loc_addr5,	
	no_pallets,	
	shipper_no,	
	shipper_name,	
	shipper_addr1,	
	shipper_addr2,	
	shipper_city,	
	shipper_state,	
	shipper_zip,	
	cust_code,	
	freight_type,	
	note,		
	rec_no		
	)
SELECT	@transfer_id,	
	@beg_location,	
	@end_location,	
	@end_datetime,	
	@beg_datetime,	
	NULL,		
	getdate(),	
	NULL,		
	@who,		
	'N',		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	0.00,		
	'N',		
	0,		
	0,		
	NULL,		
	NULL,		
	NULL,		
	TL.name,	
	TL.addr1,	
	TL.addr2,	
	TL.addr3,	
	TL.addr4,	
	TL.addr5,	
	0,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	0		
FROM	dbo.locations_all TL
WHERE	TL.location = @end_location


UPDATE	dbo.next_xfer_no
SET	last_no = @transfer_id
FROM	dbo.next_xfer_no NXN (TABLOCKX)





SELECT	@transfer_line=IsNull(MAX(XL.line_no),0) + 1
FROM	dbo.xfer_list XL
WHERE	XL.xfer_no = @transfer_id

INSERT	dbo.xfer_list
	(
	xfer_no,	
	line_no,	
	from_loc,	
	to_loc,		
	part_no,	
	description,	
	time_entered,	
	ordered,	
	shipped,	
	comment,	
	status,		
	cost,		
	com_flag,	
	who_entered,	
	temp_cost,	
	uom,		
	conv_factor,	
	std_cost,	
	from_bin,	
	to_bin,		
	lot_ser,	
	date_expires,	
	lb_tracking,	
	labor,		
	direct_dolrs,	
	ovhd_dolrs,	
	util_dolrs	
	)
SELECT	@transfer_id,	
	@transfer_line,	
	@beg_location,	
	@end_location,	
	SI.part_no,	
	IM.description,	
	getdate(),	
	SI.uom_qty,	
	0.00,		
	NULL,		
	'N',		
	0.00,		
	NULL,		
	@who,		
	0.00,		
	SI.uom,		
	1.0,		
	0.00,		
	NULL,		
	NULL,		
	NULL,		
	NULL,		
	IM.lb_tracking,	
	0.00,		
	0.00,		
	0.00,		
	0.00		
FROM	dbo.sched_item SI,
	dbo.inv_master IM
WHERE	SI.sched_transfer_id = @sched_transfer_id
AND	IM.part_no = SI.part_no

COMMIT TRANSACTION

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_release_sched_transfer] TO [public]
GO
