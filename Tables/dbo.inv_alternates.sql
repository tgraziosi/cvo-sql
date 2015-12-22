CREATE TABLE [dbo].[inv_alternates]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alt_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sugg_qty] [int] NOT NULL,
[alt_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__inv_alter__alt_t__0D1BD84B] DEFAULT ('C'),
[alt_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[inv_alternates] ADD CONSTRAINT [CK_inv_alternates_alt_type] CHECK (([alt_type]='U' OR [alt_type]='D' OR [alt_type]='C'))
GO
CREATE UNIQUE CLUSTERED INDEX [PK_inv_alternates] ON [dbo].[inv_alternates] ([part_no], [alt_part]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[inv_alternates] ADD CONSTRAINT [FK_inv_alternates_inv_master_alt_part] FOREIGN KEY ([alt_part]) REFERENCES [dbo].[inv_master] ([part_no])
GO
ALTER TABLE [dbo].[inv_alternates] ADD CONSTRAINT [FK_inv_alternates_inv_master_part_no] FOREIGN KEY ([part_no]) REFERENCES [dbo].[inv_master] ([part_no])
GO
GRANT REFERENCES ON  [dbo].[inv_alternates] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_alternates] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_alternates] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_alternates] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_alternates] TO [public]
GO
