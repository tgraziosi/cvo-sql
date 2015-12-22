CREATE TABLE [dbo].[adm_pomchtaxdtl]
(
[timestamp] [timestamp] NOT NULL,
[match_ctrl_int] [int] NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_sequence_id] [int] NOT NULL,
[detail_sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_final_tax] [float] NOT NULL,
[recoverable_flag] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_pomchtaxdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_pomchtaxdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_pomchtaxdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_pomchtaxdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_pomchtaxdtl] TO [public]
GO
