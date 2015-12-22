CREATE TABLE [dbo].[gltcDocTaxOverride]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [int] NOT NULL,
[line] [int] NOT NULL,
[TaxOverrided] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltcDocTaxOverride] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcDocTaxOverride] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcDocTaxOverride] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcDocTaxOverride] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcDocTaxOverride] TO [public]
GO
