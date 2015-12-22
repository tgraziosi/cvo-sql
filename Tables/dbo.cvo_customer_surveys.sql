CREATE TABLE [dbo].[cvo_customer_surveys]
(
[order_no] [int] NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_date] [datetime] NULL,
[survey_status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_ip] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [datetime] NULL,
[fail_reason] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [smallint] NOT NULL IDENTITY(1, 1),
[territory_code] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_code] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_start] [datetime] NULL,
[isContacted] [smallint] NULL CONSTRAINT [DF__cvo_custo__isCon__407D7B02] DEFAULT ('0'),
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_customer_surveys] ADD CONSTRAINT [PK__cvo_customer_sur__19A142FE] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
