CREATE TABLE [dbo].[cvo_upc_SCANDATA]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[UPC_CODE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[datetime] [datetime] NULL,
[fct] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_upc_SCANDATA] ADD CONSTRAINT [PK__cvo_upc_SCANDATA__41C73E83] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_upc_SCANDATA] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_upc_SCANDATA] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_upc_SCANDATA] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_upc_SCANDATA] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_upc_SCANDATA] TO [public]
GO
