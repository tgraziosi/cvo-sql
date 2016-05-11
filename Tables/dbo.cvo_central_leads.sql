CREATE TABLE [dbo].[cvo_central_leads]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[lead_source] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_date] [datetime] NULL,
[category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fname] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lname] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_centr__count__61041D37] DEFAULT ('US'),
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[validAddress] [tinyint] NULL CONSTRAINT [DF__cvo_centr__valid__61F84170] DEFAULT ((0)),
[lead_status] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_centr__lead___62EC65A9] DEFAULT ('New'),
[lead_category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_action] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_comments] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assignee] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assign_alert] [tinyint] NULL CONSTRAINT [DF__cvo_centr__assig__23C604CD] DEFAULT ((0)),
[assign_territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assigned_date] [datetime] NULL,
[assigned_by] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isLeadValid] [tinyint] NULL CONSTRAINT [DF__cvo_centr__isLea__49EBADB5] DEFAULT ((1)),
[other] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [smallint] NULL,
[ship_to] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_central_leads] ADD CONSTRAINT [PK__cvo_central_lead__600FF8FE] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO