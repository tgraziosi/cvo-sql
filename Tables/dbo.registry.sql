CREATE TABLE [dbo].[registry]
(
[timestamp] [timestamp] NOT NULL,
[registry_id] [int] NOT NULL IDENTITY(1, 1),
[parent_id] [int] NULL,
[registry_name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[registry_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[registry_data] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[registry_d]
ON [dbo].[registry]
FOR DELETE
AS
BEGIN
DECLARE	@rowcount INT


UPDATE	dbo.registry
SET	registry_type = 'X'
FROM	dbo.registry R,
	deleted D
WHERE	R.parent_id = D.registry_id

WHILE @@rowcount > 0
	UPDATE	dbo.registry
	SET	registry_type = 'X'
	WHERE	registry_type <> 'X'
	AND	parent_id IN (SELECT registry_id FROM dbo.registry WHERE registry_type = 'X')

DELETE	dbo.registry
WHERE	registry_type = 'X'

RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[registry_i]
ON [dbo].[registry]
FOR INSERT
AS
BEGIN
DECLARE	@rowcount INT,
	@tstcount INT,
	@subcount INT


SELECT @rowcount=@@rowcount


SELECT	@subcount = COUNT(*)
FROM	inserted I
WHERE	I.parent_id IS NOT NULL

SELECT	@tstcount = COUNT(*)
FROM	dbo.registry R,
	inserted I
WHERE	R.registry_id = I.parent_id

IF @tstcount <> @subcount
	BEGIN
	ROLLBACK TRANSACTION
	exec adm_raiserror 89500 ,'Illegal column value. PARENT_ID not found in REGISTRY'
	RETURN
	END

RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved. */
CREATE TRIGGER [dbo].[registry_u]
ON [dbo].[registry]
FOR UPDATE
AS
BEGIN


IF UPDATE(parent_id)
	BEGIN
	ROLLBACK TRANSACTION
	exec adm_raiserror 99500,'Illegal attempt to prune and graft REGISTRY tree'
	RETURN
	END

RETURN
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [parent] ON [dbo].[registry] ([parent_id], [registry_name]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [registry] ON [dbo].[registry] ([registry_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[registry] TO [public]
GO
GRANT SELECT ON  [dbo].[registry] TO [public]
GO
GRANT INSERT ON  [dbo].[registry] TO [public]
GO
GRANT DELETE ON  [dbo].[registry] TO [public]
GO
GRANT UPDATE ON  [dbo].[registry] TO [public]
GO
