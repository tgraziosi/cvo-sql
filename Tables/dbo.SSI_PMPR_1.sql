CREATE TABLE [dbo].[SSI_PMPR_1]
(
[PARAMETERID] [int] NOT NULL,
[PRODUCTID] [int] NOT NULL,
[LOCATIONID] [int] NOT NULL,
[FIELDENUM] [int] NOT NULL,
[FIELDNAME] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FIELDVALUE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_dbo_SSI_PMPR_1_1] ON [dbo].[SSI_PMPR_1] ([PRODUCTID], [LOCATIONID], [FIELDENUM], [PARAMETERID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_PMPR_1] ADD CONSTRAINT [FK__SSI_PMPR___PARAM__6BB2598D] FOREIGN KEY ([PARAMETERID]) REFERENCES [dbo].[SSI_PARM_1] ([PARAMETERID])
GO
GRANT SELECT ON  [dbo].[SSI_PMPR_1] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_PMPR_1] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_PMPR_1] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_PMPR_1] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_PMPR_1] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_PMPR_1] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_PMPR_1] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_PMPR_1] TO [public]
GO
