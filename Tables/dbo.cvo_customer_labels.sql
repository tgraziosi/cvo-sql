CREATE TABLE [dbo].[cvo_customer_labels]
(
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_date] [datetime] NULL,
[user_login] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking_number] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_path] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_weight] [float] NULL,
[label_service] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_package_type] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_tracking] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [int] NOT NULL IDENTITY(1, 1),
[label_cost] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_customer_labels] ADD CONSTRAINT [PK__cvo_customer_lab__465D75F8] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
