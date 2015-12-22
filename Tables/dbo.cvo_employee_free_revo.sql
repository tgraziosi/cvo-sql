CREATE TABLE [dbo].[cvo_employee_free_revo]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[user_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [datetime] NULL,
[sku] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isOrdered] [tinyint] NULL CONSTRAINT [DF__cvo_emplo__isOrd__36A89321] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_employee_free_revo] ADD CONSTRAINT [PK__cvo_employee_fre__35B46EE8] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
