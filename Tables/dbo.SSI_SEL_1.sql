CREATE TABLE [dbo].[SSI_SEL_1]
(
[REFNUM] [int] NOT NULL,
[PRODUCTID] [int] NOT NULL,
[LOCATIONID] [int] NOT NULL,
[SELECTED] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_dbo_SSI_SEL_1_1] ON [dbo].[SSI_SEL_1] ([PRODUCTID], [LOCATIONID], [REFNUM]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_SEL_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_SEL_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_SEL_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_SEL_1] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_SEL_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_SEL_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_SEL_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_SEL_1] TO [public]
GO
