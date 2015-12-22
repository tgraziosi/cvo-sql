CREATE TABLE [dbo].[cvo_surveys]
(
[survey_type] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_date] [datetime] NULL,
[survey_status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_ip] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[visited_date] [datetime] NULL,
[order_date] [datetime] NULL,
[customer_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rx_user] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [smallint] NOT NULL IDENTITY(1, 1),
[survey_id] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isContacted] [tinyint] NULL CONSTRAINT [DF__cvo_surve__isCon__0BCE7FAB] DEFAULT ((0)),
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_surveys] ADD CONSTRAINT [PK__cvo_surveys__20549B45] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
