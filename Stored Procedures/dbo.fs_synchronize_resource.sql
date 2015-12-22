SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_synchronize_resource]
AS
BEGIN
DECLARE @asm_no		VARCHAR(30),
	@seq_no		VARCHAR(4),
	@message	VARCHAR(60),
	@rowcount	INT,
	@calendar_id	INT

create table #t1 (resource_type_id int)					-- mls SCR 31863  9/9/03


SELECT	@calendar_id=C.calendar_id
FROM	dbo.calendar C
WHERE	C.usage_flag = 'D'

IF @@rowcount <> 1
	BEGIN
	RaisError 69009 'Unable to synchronize resource without a default calendar'
	RETURN
	END

BEGIN TRANSACTION




insert #t1								-- mls SCR 31863 9/9/03 start
select distinct resource_type_id
FROM	dbo.resource_type RT (TABLOCKX)
WHERE	NOT EXISTS (	SELECT	*
			FROM	dbo.inv_master IM
			WHERE	IM.type_code <> '#IGNORE'
			AND	IM.part_no = RT.resource_type_code
			AND	IM.status = 'R'
			AND	(	IM.void = 'N'
				OR	IM.void IS NULL ))

delete SOR
from sched_operation_resource SOR
join sched_resource SR on SR.sched_resource_id = SOR.sched_resource_id
join resource R on R.resource_id = SR.resource_id
join #t1 t on t.resource_type_id = R.resource_type_id

delete SR
from sched_resource SR 
join resource R on R.resource_id = SR.resource_id
join #t1 t on t.resource_type_id = R.resource_type_id

delete R
from resource R 
join #t1 t on t.resource_type_id = R.resource_type_id			-- mls SCR 31863 9/9/03 end





DELETE	dbo.resource_type						-- mls 9/9/03 SCR 31863
FROM	dbo.resource_type RT (TABLOCKX), #t1 t
WHERE	RT.resource_type_id = t.resource_type_id

INSERT	dbo.resource_type(resource_type_code,resource_type_name)
SELECT	DISTINCT IM.part_no,Coalesce(IM.description,IM.part_no)
FROM	dbo.inv_master IM
WHERE	IM.type_code <> '#IGNORE'
AND	IM.status = 'R'
AND	(	IM.void = 'N'
	OR	IM.void IS NULL )
AND	NOT EXISTS (	SELECT	*
			FROM	dbo.resource_type RT
			WHERE	IM.part_no = RT.resource_type_code )

UPDATE 	dbo.resource_type
SET	resource_type_name = Coalesce(IM.description,IM.part_no)
FROM	dbo.resource_type RT,
	dbo.inv_master IM
WHERE	RT.resource_type_name <> Coalesce(IM.description,IM.part_no)
AND	IM.part_no = RT.resource_type_code
AND	IM.status = 'R'





UPDATE	dbo.resource
SET	pool_qty = IL.max_stock
FROM	dbo.resource R,
	dbo.inv_list IL
WHERE   IL.location = R.location
AND	IL.part_no = R.resource_code
AND	IL.max_stock <> R.pool_qty

INSERT	dbo.resource(location,resource_type_id,resource_code,resource_name,calendar_id,pool_qty)
SELECT	L.location,RT.resource_type_id,RT.resource_type_code,RT.resource_type_name,@calendar_id,IL.max_stock
FROM    dbo.locations_all L,
	dbo.resource_type RT,
	dbo.inv_list IL
WHERE   IL.location = L.location
AND	IL.part_no = RT.resource_type_code
AND	IL.status = 'R'
AND	(	IL.void = 'N'
	OR	IL.void IS NULL )
AND	NOT EXISTS (	SELECT	*
			FROM	dbo.resource R
			WHERE	R.resource_type_id = RT.resource_type_id
			AND	R.location = L.location )

COMMIT TRANSACTION

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_synchronize_resource] TO [public]
GO
