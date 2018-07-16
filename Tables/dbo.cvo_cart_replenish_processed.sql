CREATE TABLE [dbo].[cvo_cart_replenish_processed]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[queue_date] [datetime] NULL,
[cart_no] [int] NULL,
[pick_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id] [int] NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_bin] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[target_bin] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_qty] [int] NULL,
[isSkipped] [tinyint] NULL CONSTRAINT [DF__cvo_cart___isSki__184A624A] DEFAULT ('0'),
[source_pick] [int] NULL,
[target_put] [int] NULL,
[isPicked] [int] NULL CONSTRAINT [DF__cvo_cart___isPic__193E8683] DEFAULT ('0'),
[isPut] [int] NULL CONSTRAINT [DF__cvo_cart___isPut__1A32AABC] DEFAULT ('0'),
[reason_code] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_time] [datetime] NULL,
[put_time] [datetime] NULL,
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_slot] [tinyint] NULL,
[end_slot] [tinyint] NULL,
[put_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cart_replenish_processed] ADD CONSTRAINT [PK__cvo_cart_repleni__17563E11] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
