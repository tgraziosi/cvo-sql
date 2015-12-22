CREATE TABLE [dbo].[smvendorgrpdet]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [int] NOT NULL,
[vendor_mask] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smvendorgrpdet_ind_0] ON [dbo].[smvendorgrpdet] ([group_id], [sequence_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [smvendorgrpdet_ind_1] ON [dbo].[smvendorgrpdet] ([group_id], [vendor_mask]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[smvendorgrpdet] TO [public]
GO
GRANT SELECT ON  [dbo].[smvendorgrpdet] TO [public]
GO
GRANT INSERT ON  [dbo].[smvendorgrpdet] TO [public]
GO
GRANT DELETE ON  [dbo].[smvendorgrpdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[smvendorgrpdet] TO [public]
GO
