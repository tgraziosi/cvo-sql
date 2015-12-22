CREATE TABLE [dbo].[cvo_employee_free_revo_orders]
(
[ord_id] [int] NOT NULL IDENTITY(1, 1),
[sku] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [datetime] NULL,
[order_status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_emplo__order__6FE1107D] DEFAULT ('Progress')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_employee_free_revo_orders] ADD CONSTRAINT [PK__cvo_employee_fre__6EECEC44] PRIMARY KEY CLUSTERED  ([ord_id]) ON [PRIMARY]
GO
