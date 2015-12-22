CREATE TABLE [dbo].[tdc_3pl_templates]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[template_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[charge_per_day] [decimal] (20, 8) NULL,
[currency] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[free_days_begin] [int] NULL,
[free_days_end] [int] NULL,
[sp_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value] [decimal] (20, 8) NULL,
[created_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[created_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[modified_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_3pl_templates] ADD CONSTRAINT [PK_tdc_3pl_templates] PRIMARY KEY CLUSTERED  ([location], [template_name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_templates_idx1] ON [dbo].[tdc_3pl_templates] ([location], [template_name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_templates_idx2] ON [dbo].[tdc_3pl_templates] ([template_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_templates] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_templates] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_templates] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_templates] TO [public]
GO
