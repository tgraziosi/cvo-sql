CREATE TABLE [dbo].[cvo_master_pack]
(
[pack_no] [int] NULL,
[pack_option] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cvo_master_pack_ind0] ON [dbo].[cvo_master_pack] ([pack_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_master_pack] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_master_pack] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_master_pack] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_master_pack] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_master_pack] TO [public]
GO
