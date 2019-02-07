CREATE TABLE [dbo].[cvo_evites_external_orders]
(
[order_incr] [bigint] NOT NULL IDENTITY(100000000, 1),
[evite_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [datetime] NULL CONSTRAINT [DF__cvo_evite__order__6C41C2DA] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_evites_external_orders] ADD CONSTRAINT [PK__cvo_evites_exter__6B4D9EA1] PRIMARY KEY CLUSTERED  ([order_incr]) ON [PRIMARY]
GO
