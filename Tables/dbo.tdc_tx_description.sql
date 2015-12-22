CREATE TABLE [dbo].[tdc_tx_description]
(
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source_desc] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_desc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_desc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_tx_description] ADD CONSTRAINT [PK_tdc_tx_description] PRIMARY KEY NONCLUSTERED  ([trans_source], [module], [trans]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [idx_tdc_tx_description] ON [dbo].[tdc_tx_description] ([trans_source], [module], [trans]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_tx_description] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_tx_description] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_tx_description] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_tx_description] TO [public]
GO
