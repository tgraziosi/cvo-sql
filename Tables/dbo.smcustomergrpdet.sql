CREATE TABLE [dbo].[smcustomergrpdet]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [int] NOT NULL,
[customer_mask] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smcustomergrpdet_ind_1] ON [dbo].[smcustomergrpdet] ([group_id], [customer_mask]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smcustomergrpdet_ind_0] ON [dbo].[smcustomergrpdet] ([group_id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smcustomergrpdet] TO [public]
GO
GRANT SELECT ON  [dbo].[smcustomergrpdet] TO [public]
GO
GRANT INSERT ON  [dbo].[smcustomergrpdet] TO [public]
GO
GRANT DELETE ON  [dbo].[smcustomergrpdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[smcustomergrpdet] TO [public]
GO
