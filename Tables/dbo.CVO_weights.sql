CREATE TABLE [dbo].[CVO_weights]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Weight_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wgt] [decimal] (20, 8) NULL,
[charge] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [cvo_weights_idx1] ON [dbo].[CVO_weights] ([Weight_code], [wgt]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_weights] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_weights] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_weights] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_weights] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_weights] TO [public]
GO
