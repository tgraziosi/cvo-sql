CREATE TABLE [dbo].[cvo_comm_pclass]
(
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[commission_pct] [decimal] (5, 2) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cvo_comm_pclass_ind0] ON [dbo].[cvo_comm_pclass] ([price_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_comm_pclass] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_comm_pclass] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_comm_pclass] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_comm_pclass] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_comm_pclass] TO [public]
GO
