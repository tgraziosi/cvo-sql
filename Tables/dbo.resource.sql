CREATE TABLE [dbo].[resource]
(
[timestamp] [timestamp] NOT NULL,
[resource_id] [int] NOT NULL IDENTITY(1, 1),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[resource_type_id] [int] NOT NULL,
[resource_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[resource_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[calendar_id] [int] NOT NULL,
[pool_qty] [float] NOT NULL CONSTRAINT [DF__resource__pool_q__3A788EA7] DEFAULT ((1.0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[resource_d]
ON [dbo].[resource]
FOR DELETE
AS
BEGIN


    if (@@version like '%7.0%')							-- mls 6/9/03 SCR 31372 start
    begin
      delete SOR
      FROM	sched_operation_resource SOR, deleted D
      WHERE	SOR.sched_resource_id = D.resource_id
    end

    DELETE SR
    FROM	sched_resource SR, deleted D
    WHERE	SR.sched_resource_id = D.resource_id				-- mls 6/9/03 SCR 31372 end


DELETE	dbo.resource_pool
FROM	deleted D,
	dbo.resource_pool RP
WHERE	RP.resource_id = D.resource_id

RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[resource_iu]
ON [dbo].[resource]

FOR INSERT, UPDATE
AS
BEGIN
DECLARE	@rowcount INT,
	@tstcount INT


SELECT @rowcount=@@rowcount


IF UPDATE(resource_type_id)
	BEGIN
	SELECT	@tstcount = COUNT(*)
	FROM	dbo.resource_type RT,
		inserted I
	WHERE	RT.resource_type_id = I.resource_type_id

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89700,'Illegal column value. RESOURCE_TYPE_ID not found in RESOURCE_TYPE'
		RETURN
		END
	END


IF UPDATE(location)
	BEGIN
	SELECT	@tstcount=COUNT(*)
	FROM	dbo.locations_all L,
		inserted I
	WHERE	L.location = I.location

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89701, 'Illegal column value. LOCATION not found in LOCATIONS'
		RETURN
		END
	END

RETURN
END
GO
CREATE NONCLUSTERED INDEX [rsrcem1] ON [dbo].[resource] ([location], [resource_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [resource] ON [dbo].[resource] ([resource_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[resource] TO [public]
GO
GRANT SELECT ON  [dbo].[resource] TO [public]
GO
GRANT INSERT ON  [dbo].[resource] TO [public]
GO
GRANT DELETE ON  [dbo].[resource] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource] TO [public]
GO
