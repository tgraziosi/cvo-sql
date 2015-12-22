CREATE TABLE [dbo].[rpt_amassetype]
(
[asset_type_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_gl_override] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accum_depr_gl_override] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depr_exp_gl_override] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amassetype] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amassetype] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amassetype] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amassetype] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amassetype] TO [public]
GO
