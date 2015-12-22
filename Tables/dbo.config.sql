CREATE TABLE [dbo].[config]
(
[timestamp] [timestamp] NOT NULL,
[flag] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[value_str] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[flag_class] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__config__flag_cla__53E35AEF] DEFAULT ('misc')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[config_upd]
ON [dbo].[config] 
FOR UPDATE
AS
BEGIN

if (SELECT value_str from inserted WHERE flag = 'PUR_INV_REPL') = 'YES'
begin
	if (SELECT COUNT(*) FROM resource_batch WHERE batch_id = 'SCHEDULER') = 0
	begin
		--*****************************************************************************
		--* If the user is changing the config option to use the eBO Scheduler for 
		--* suggesting planned purchase orders in Inventory Replenishment, then insert
		--* a row in resource batch with the appropriate primary key so that the Scheduler
		--* can insert rows in resource_demand_group.  
		--*****************************************************************************
		INSERT	resource_batch(batch_id, batch_date, combine_days, time_fence_end_date)
		VALUES	( 'SCHEDULER', getdate(), 1, getdate() )
	end
end
if exists (select 1 from inserted i, deleted d 
		where i.flag='EFORECAST_CONFIG' 
		and d.flag = 'EFORECAST_CONFIG' 
		and i.value_str <> d.value_str)
	EXEC fs_populate_eforecast_time_table
RETURN
END
GO
CREATE UNIQUE CLUSTERED INDEX [config1] ON [dbo].[config] ([flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [_WA_Sys_value_str_1F2940D6] ON [dbo].[config] ([value_str]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[config] TO [public]
GO
GRANT SELECT ON  [dbo].[config] TO [public]
GO
GRANT INSERT ON  [dbo].[config] TO [public]
GO
GRANT DELETE ON  [dbo].[config] TO [public]
GO
GRANT UPDATE ON  [dbo].[config] TO [public]
GO
