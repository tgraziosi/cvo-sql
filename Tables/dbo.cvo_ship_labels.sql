CREATE TABLE [dbo].[cvo_ship_labels]
(
[label_date] [datetime] NULL,
[postal_service] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_cost] [float] NULL,
[mail_class] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[package_type] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[run_id] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail_weight] [int] NULL,
[mail_dimensions] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_path] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking_number] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_rep] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_rep_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[postal_transaction] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isVoid] [smallint] NULL CONSTRAINT [DF__cvo_ship___isVoi__1CA70184] DEFAULT ((0)),
[issue_user] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[track_update] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[track_time] [datetime] NULL,
[tracked_refresh] [datetime] NULL,
[update_user] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[update_time] [datetime] NULL,
[package_weight] [float] NULL,
[isArchived] [tinyint] NULL CONSTRAINT [DF__cvo_ship___isArc__5A103441] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
