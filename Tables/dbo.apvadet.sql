CREATE TABLE [dbo].[apvadet]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apvadet_ind_0] ON [dbo].[apvadet] ([trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apvadet] TO [public]
GO
GRANT SELECT ON  [dbo].[apvadet] TO [public]
GO
GRANT INSERT ON  [dbo].[apvadet] TO [public]
GO
GRANT DELETE ON  [dbo].[apvadet] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvadet] TO [public]
GO
