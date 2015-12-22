CREATE TABLE [dbo].[order_priority]
(
[timestamp] [timestamp] NOT NULL,
[order_priority_id] [int] NOT NULL IDENTITY(1, 1),
[priority_code] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority_name] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_rank] [int] NOT NULL,
[process_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[usage_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[order_priority_d]
ON [dbo].[order_priority]
FOR DELETE
AS
BEGIN


IF EXISTS(SELECT * FROM dbo.sched_order SO, deleted D WHERE SO.order_priority_id = D.order_priority_id)
	BEGIN
	ROLLBACK TRANSACTION
	exec adm_raiserror 79009 ,'Reference in use. ORDER_PRIORITY_ID in use in SCHED_ORDER'
	RETURN
	END
	

RETURN
END
GO
CREATE UNIQUE CLUSTERED INDEX [order_priority] ON [dbo].[order_priority] ([order_priority_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [priority_code] ON [dbo].[order_priority] ([priority_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[order_priority] TO [public]
GO
GRANT SELECT ON  [dbo].[order_priority] TO [public]
GO
GRANT INSERT ON  [dbo].[order_priority] TO [public]
GO
GRANT DELETE ON  [dbo].[order_priority] TO [public]
GO
GRANT UPDATE ON  [dbo].[order_priority] TO [public]
GO
