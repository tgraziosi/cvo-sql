CREATE TABLE [dbo].[SSI_CNV_1]
(
[CONVERSIONID] [int] NOT NULL,
[PRODUCTID] [int] NOT NULL,
[LOCATIONID] [int] NOT NULL,
[CONVERSION] [real] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_SSI_CNV_1_1] ON [dbo].[SSI_CNV_1] ([PRODUCTID], [LOCATIONID], [CONVERSIONID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_CNV_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_CNV_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_CNV_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_CNV_1] TO [epicoradmin]
GO
GRANT REFERENCES ON  [dbo].[SSI_CNV_1] TO [public]
GO
GRANT SELECT ON  [dbo].[SSI_CNV_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_CNV_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_CNV_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_CNV_1] TO [public]
GO