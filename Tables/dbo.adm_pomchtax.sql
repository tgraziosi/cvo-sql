CREATE TABLE [dbo].[adm_pomchtax]
(
[timestamp] [timestamp] NOT NULL,
[match_ctrl_int] [int] NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_final_tax] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [adm_pomchtax_ind1] ON [dbo].[adm_pomchtax] ([match_ctrl_int], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_pomchtax] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_pomchtax] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_pomchtax] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_pomchtax] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_pomchtax] TO [public]
GO
