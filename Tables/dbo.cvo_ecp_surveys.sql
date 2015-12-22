CREATE TABLE [dbo].[cvo_ecp_surveys]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[survey_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_date] [datetime] NULL,
[survey_status] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_ip] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[visited_date] [datetime] NULL,
[order_date] [datetime] NULL,
[territory] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_id] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_ecp_surveys] ADD CONSTRAINT [PK__cvo_ecp_surveys__581473E4] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
