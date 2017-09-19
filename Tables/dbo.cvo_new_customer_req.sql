CREATE TABLE [dbo].[cvo_new_customer_req]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_new_c__statu__490CC9DF] DEFAULT ('NEW'),
[territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rep_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rep_email] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_req_type] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[req_data] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[datetime] [datetime] NOT NULL CONSTRAINT [DF__cvo_new_c__datet__4A00EE18] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_new_customer_req] ADD CONSTRAINT [PK__cvo_new_customer__4818A5A6] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
