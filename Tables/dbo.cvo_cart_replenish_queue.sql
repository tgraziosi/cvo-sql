CREATE TABLE [dbo].[cvo_cart_replenish_queue]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[queue_date] [datetime] NULL,
[cart_no] [int] NULL,
[scan_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id] [int] NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_bin] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[target_bin] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_qty] [int] NULL,
[isSkipped] [tinyint] NULL CONSTRAINT [DF__cvo_cart___isSki__7747CA84] DEFAULT ('0'),
[source_pick] [int] NULL,
[target_put] [int] NULL,
[isPicked] [int] NULL CONSTRAINT [DF__cvo_cart___isPic__7EE8EC4C] DEFAULT ('0'),
[isPut] [int] NULL CONSTRAINT [DF__cvo_cart___isPut__7FDD1085] DEFAULT ('0'),
[reason_code] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_time] [datetime] NULL,
[put_time] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cart_replenish_queue] ADD CONSTRAINT [PK__cvo_cart_repleni__7653A64B] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
