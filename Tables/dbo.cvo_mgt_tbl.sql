CREATE TABLE [dbo].[cvo_mgt_tbl]
(
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[mgt_date] [datetime] NOT NULL,
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_mgt_tbl] ADD CONSTRAINT [PK_cvo_mgt_tbl] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
