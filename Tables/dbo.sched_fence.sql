CREATE TABLE [dbo].[sched_fence]
(
[timestamp] [timestamp] NOT NULL,
[sched_fence_id] [int] NOT NULL IDENTITY(1, 1),
[fence_name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fence_time] [int] NOT NULL,
[fence_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[plan_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[sched_fence_d]
ON [dbo].[sched_fence]

FOR DELETE
AS
BEGIN


DELETE	dbo.sched_fence_user
FROM	dbo.sched_fence_user SFU,
	deleted D
WHERE	SFU.sched_fence_id = D.sched_fence_id

RETURN
END
GO
CREATE UNIQUE NONCLUSTERED INDEX [fence_name] ON [dbo].[sched_fence] ([fence_name]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_fence] ON [dbo].[sched_fence] ([sched_fence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sched_fence] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_fence] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_fence] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_fence] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_fence] TO [public]
GO
