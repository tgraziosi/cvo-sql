CREATE TABLE [dbo].[aphisage]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_aging] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aphisage_ind_0] ON [dbo].[aphisage] ([trx_ctrl_num], [date_aging]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aphisage] TO [public]
GO
GRANT SELECT ON  [dbo].[aphisage] TO [public]
GO
GRANT INSERT ON  [dbo].[aphisage] TO [public]
GO
GRANT DELETE ON  [dbo].[aphisage] TO [public]
GO
GRANT UPDATE ON  [dbo].[aphisage] TO [public]
GO
