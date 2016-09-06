CREATE TABLE [dbo].[cvo_kindness_request]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[isCustomer] [tinyint] NULL CONSTRAINT [DF__cvo_kindn__isCus__16284BA4] DEFAULT ((1)),
[account_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pros_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pros_company] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pros_addr1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pros_addr2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[items_qty] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[message] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[request_date] [datetime] NULL,
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking_status] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[requestor_name] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[requestor_email] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_kindn__reque__6ABF9609] DEFAULT (NULL),
[who_mail] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_kindn__who_m__6BB3BA42] DEFAULT (NULL),
[date_mailed] [datetime] NULL CONSTRAINT [DF__cvo_kindn__date___6CA7DE7B] DEFAULT (NULL)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_kindness_request] ADD CONSTRAINT [PK__cvo_kindness_req__1534276B] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
