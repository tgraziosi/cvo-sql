CREATE TABLE [dbo].[cvo_inv_features]
(
[Collection] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_no] [int] NULL,
[feature_id] [int] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [cvo_inv_features_idx0] ON [dbo].[cvo_inv_features] ([Collection], [style], [part_no], [seq_no], [feature_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_inv_features] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_features] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_features] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_features] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_features] TO [public]
GO
