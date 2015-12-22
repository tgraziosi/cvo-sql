CREATE TABLE [dbo].[gl_taxrep_dtl]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_date] [int] NOT NULL,
[tax_box_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NULL,
[amt_tax] [float] NULL,
[trx_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_taxrep_dtl_0] ON [dbo].[gl_taxrep_dtl] ([trx_ctrl_num], [trx_type], [tax_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_taxrep_dtl] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_taxrep_dtl] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_taxrep_dtl] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_taxrep_dtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_taxrep_dtl] TO [public]
GO
