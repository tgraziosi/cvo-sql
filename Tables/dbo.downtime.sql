CREATE TABLE [dbo].[downtime]
(
[timestamp] [timestamp] NOT NULL,
[downtime_id] [int] NOT NULL IDENTITY(1, 1),
[downtime_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[downtime_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[downtime_d]
ON [dbo].[downtime]

FOR DELETE
AS
BEGIN

DELETE	dbo.calendar_downtime
FROM	dbo.calendar_downtime CD,
	deleted D
WHERE	CD.downtime_id = D.downtime_id

RETURN
END
GO
CREATE UNIQUE CLUSTERED INDEX [downtime] ON [dbo].[downtime] ([downtime_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[downtime] TO [public]
GO
GRANT SELECT ON  [dbo].[downtime] TO [public]
GO
GRANT INSERT ON  [dbo].[downtime] TO [public]
GO
GRANT DELETE ON  [dbo].[downtime] TO [public]
GO
GRANT UPDATE ON  [dbo].[downtime] TO [public]
GO
