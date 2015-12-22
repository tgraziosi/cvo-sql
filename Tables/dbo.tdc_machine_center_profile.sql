CREATE TABLE [dbo].[tdc_machine_center_profile]
(
[machine_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[run_hours_shift_1] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_machi__run_h__638E1C25] DEFAULT ((0)),
[run_hours_shift_2] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_machi__run_h__6482405E] DEFAULT ((0)),
[run_hours_shift_3] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__tdc_machi__run_h__65766497] DEFAULT ((0)),
[base_uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bundle_uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pool] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_machine_center_profile_idx0] ON [dbo].[tdc_machine_center_profile] ([machine_code], [location]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_machine_center_profile_idx1] ON [dbo].[tdc_machine_center_profile] ([pool], [machine_code], [location]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_machine_center_profile] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_machine_center_profile] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_machine_center_profile] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_machine_center_profile] TO [public]
GO
