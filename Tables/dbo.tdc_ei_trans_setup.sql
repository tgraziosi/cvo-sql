CREATE TABLE [dbo].[tdc_ei_trans_setup]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[plan_trans_day] [int] NOT NULL,
[plan_hours_day] [decimal] (8, 2) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_ei_trans_setup] ADD CONSTRAINT [loc_tran_pk] PRIMARY KEY CLUSTERED  ([location], [module], [trans]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_ei_trans_setup] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_ei_trans_setup] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_ei_trans_setup] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_ei_trans_setup] TO [public]
GO
