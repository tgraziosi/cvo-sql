CREATE TABLE [dbo].[tdc_ei_avg_wage]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[avg_wage] [decimal] (8, 2) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_ei_avg_wage] ADD CONSTRAINT [PK__tdc_ei_avg_wage__2A559EC9] PRIMARY KEY CLUSTERED  ([location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_ei_avg_wage] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_ei_avg_wage] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_ei_avg_wage] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_ei_avg_wage] TO [public]
GO
