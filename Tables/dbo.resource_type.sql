CREATE TABLE [dbo].[resource_type]
(
[timestamp] [timestamp] NOT NULL,
[resource_type_id] [int] NOT NULL IDENTITY(1, 1),
[resource_type_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[resource_type_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[resource_type_d]
ON [dbo].[resource_type]
FOR DELETE
AS
BEGIN

DELETE	dbo.resource
FROM	dbo.resource R,
	deleted D
WHERE	R.resource_type_id = D.resource_type_id

RETURN
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [resource_type_code] ON [dbo].[resource_type] ([resource_type_code]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [resource_type] ON [dbo].[resource_type] ([resource_type_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[resource_type] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_type] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_type] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_type] TO [public]
GO
