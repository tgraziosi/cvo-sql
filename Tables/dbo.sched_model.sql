CREATE TABLE [dbo].[sched_model]
(
[timestamp] [timestamp] NOT NULL,
[sched_id] [int] NOT NULL IDENTITY(1, 1),
[sched_name] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_datetime] [datetime] NULL,
[process_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__proce__4D5658F1] DEFAULT ('F'),
[beg_date] [datetime] NULL,
[end_date] [datetime] NULL,
[purchase_lead_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__purch__4E4A7D2A] DEFAULT ('I'),
[process_group_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__proce__4F3EA163] DEFAULT ('N'),
[process_batch_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__proce__5032C59C] DEFAULT ('L'),
[process_order_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__proce__5126E9D5] DEFAULT ('N'),
[stock_level_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__stock__521B0E0E] DEFAULT ('N'),
[order_usage_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__order__530F3247] DEFAULT ('U'),
[batch_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__batch__54035680] DEFAULT ('N'),
[check_schedule_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__check__54F77AB9] DEFAULT ('O'),
[check_datetime] [datetime] NULL,
[mfg_lead_time_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__mfg_l__55EB9EF2] DEFAULT ('C'),
[late_order_sched_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__late___56DFC32B] DEFAULT ('B'),
[tolerance_days_early] [int] NOT NULL CONSTRAINT [DF__sched_mod__toler__57D3E764] DEFAULT ((0)),
[tolerance_days_late] [int] NOT NULL CONSTRAINT [DF__sched_mod__toler__58C80B9D] DEFAULT ((0)),
[planning_time_fence] [int] NOT NULL CONSTRAINT [DF__sched_mod__plann__59BC2FD6] DEFAULT ((0)),
[operation_compl_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__opera__5AB0540F] DEFAULT ('P'),
[forecast_resync_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__forec__5BA47848] DEFAULT ('N'),
[forecast_delete_past_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_mod__forec__5C989C81] DEFAULT ('N'),
[forecast_horizon] [int] NOT NULL CONSTRAINT [DF__sched_mod__forec__5D8CC0BA] DEFAULT ((0)),
[transfer_demand_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__sched_mod__trans__5E80E4F3] DEFAULT ('U'),
[transfer_supply_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__sched_mod__trans__5F75092C] DEFAULT ('U'),
[solver_start_time] [datetime] NULL,
[solver_mode] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[solver_start_user] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[debug_level] [int] NULL CONSTRAINT [DF__sched_mod__debug__60692D65] DEFAULT ((0)),
[solver_options] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_model] ADD CONSTRAINT [sched_model_check_schedule_flag_cc1] CHECK (([check_schedule_flag]='M' OR [check_schedule_flag]='O' OR [check_schedule_flag]='D'))
GO
ALTER TABLE [dbo].[sched_model] ADD CONSTRAINT [CK_sched_model_forecast_delete_past_flag] CHECK (([forecast_delete_past_flag]='N' OR [forecast_delete_past_flag]='Y'))
GO
ALTER TABLE [dbo].[sched_model] ADD CONSTRAINT [CK_sched_model_forecast_resync_flag] CHECK (([forecast_resync_flag]='N' OR [forecast_resync_flag]='Y'))
GO
ALTER TABLE [dbo].[sched_model] ADD CONSTRAINT [sched_model_late_order_sched_mode_cc1] CHECK (([late_order_sched_mode]='B' OR [late_order_sched_mode]='F'))
GO
ALTER TABLE [dbo].[sched_model] ADD CONSTRAINT [sched_model_mfg_lead_time_mode_cc1] CHECK (([mfg_lead_time_mode]='C' OR [mfg_lead_time_mode]='F'))
GO
CREATE UNIQUE CLUSTERED INDEX [sched_model] ON [dbo].[sched_model] ([sched_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [sched_name] ON [dbo].[sched_model] ([sched_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sched_model] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_model] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_model] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_model] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_model] TO [public]
GO
