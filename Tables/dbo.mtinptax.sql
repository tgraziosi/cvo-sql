CREATE TABLE [dbo].[mtinptax]
(
[timestamp] [timestamp] NOT NULL,
[match_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_taxable] [float] NULL,
[amt_gross] [float] NULL,
[amt_tax] [float] NULL,
[amt_final_tax] [float] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [mtinptax_ind_0] ON [dbo].[mtinptax] ([match_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [mtinptax_ind_1] ON [dbo].[mtinptax] ([match_ctrl_num], [trx_type], [tax_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mtinptax] TO [public]
GO
GRANT SELECT ON  [dbo].[mtinptax] TO [public]
GO
GRANT INSERT ON  [dbo].[mtinptax] TO [public]
GO
GRANT DELETE ON  [dbo].[mtinptax] TO [public]
GO
GRANT UPDATE ON  [dbo].[mtinptax] TO [public]
GO
