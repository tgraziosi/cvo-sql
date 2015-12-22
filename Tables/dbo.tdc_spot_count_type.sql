CREATE TABLE [dbo].[tdc_spot_count_type]
(
[spot_count_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[empty_count_interval] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_spot_count_type] ADD CONSTRAINT [CK__tdc_spot___empty__71A73152] CHECK (([empty_count_interval]>=(1) AND [empty_count_interval]<=(9)))
GO
ALTER TABLE [dbo].[tdc_spot_count_type] ADD CONSTRAINT [PK__tdc_spot_count_t__70B30D19] PRIMARY KEY CLUSTERED  ([spot_count_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_spot_count_type] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_spot_count_type] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_spot_count_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_spot_count_type] TO [public]
GO
