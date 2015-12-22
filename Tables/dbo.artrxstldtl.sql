CREATE TABLE [dbo].[artrxstldtl]
(
[timestamp] [timestamp] NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxstldtl_ind_0] ON [dbo].[artrxstldtl] ([settlement_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxstldtl] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxstldtl] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxstldtl] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxstldtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxstldtl] TO [public]
GO
