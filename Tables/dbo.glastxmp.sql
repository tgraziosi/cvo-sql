CREATE TABLE [dbo].[glastxmp]
(
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[aust_tax_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glastxmp] TO [public]
GO
GRANT SELECT ON  [dbo].[glastxmp] TO [public]
GO
GRANT INSERT ON  [dbo].[glastxmp] TO [public]
GO
GRANT DELETE ON  [dbo].[glastxmp] TO [public]
GO
GRANT UPDATE ON  [dbo].[glastxmp] TO [public]
GO
