CREATE TABLE [dbo].[cvo_customer_care_call_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[phone] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dialog_id] [bigint] NULL,
[call_start] [datetime] NULL,
[call_agent] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[call_account] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[call_end] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_customer_care_call_log] ADD CONSTRAINT [PK__cvo_customer_car__6F478160] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
