CREATE TABLE [dbo].[EAI_RMAKit]
(
[FO_RMAID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_per] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_RMAKit] ADD CONSTRAINT [EAI_RMAKit_pk] PRIMARY KEY CLUSTERED  ([FO_RMAID], [line_no], [part_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_RMAKit] ADD CONSTRAINT [EAI_RMAKit_EAI_RMADetail_fk1] FOREIGN KEY ([FO_RMAID], [line_no]) REFERENCES [dbo].[EAI_RMADetail] ([FO_RMAID], [line_no])
GO
GRANT REFERENCES ON  [dbo].[EAI_RMAKit] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_RMAKit] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_RMAKit] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_RMAKit] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_RMAKit] TO [public]
GO
