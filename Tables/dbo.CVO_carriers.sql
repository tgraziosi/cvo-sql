CREATE TABLE [dbo].[CVO_carriers]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Weight_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Carrier] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Lower_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Upper_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Max_charge] [decimal] (20, 8) NULL,
[Max_weight] [decimal] (20, 8) NULL,
[Clippership_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Clippership_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_carrier_idx1] ON [dbo].[CVO_carriers] ([Carrier]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [cvo_carrier_idx3] ON [dbo].[CVO_carriers] ([Carrier], [Lower_zip], [Max_weight], [Upper_zip]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_carriers_idx] ON [dbo].[CVO_carriers] ([ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_carrier_idx2] ON [dbo].[CVO_carriers] ([Lower_zip], [Upper_zip]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_carriers] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_carriers] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_carriers] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_carriers] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_carriers] TO [public]
GO
