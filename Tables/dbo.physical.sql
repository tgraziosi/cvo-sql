CREATE TABLE [dbo].[physical]
(
[timestamp] [timestamp] NOT NULL,
[phy_batch] [int] NOT NULL,
[phy_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[date_entered] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[avg_cost] [decimal] (20, 8) NOT NULL,
[avg_direct_dolrs] [decimal] (20, 8) NOT NULL,
[avg_ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[avg_util_dolrs] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[close_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_qty] [decimal] (20, 8) NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_physical_lb_tracking] DEFAULT ('N'),
[serial_flag] [int] NULL CONSTRAINT [DF_physical_serial_flag] DEFAULT ((0)),
[who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[phyins700t] ON [dbo].[physical] 
FOR INSERT
AS

IF Exists( select * from inserted i, inv_master m
		where i.part_no=m.part_no and (m.status='C' or m.status='V') )
	BEGIN
		rollback tran
		exec adm_raiserror 83203, 'You can not create physical counts for Custom Kit or Non-Quantity Bearing Items.'
		RETURN
	END



GO
ALTER TABLE [dbo].[physical] ADD CONSTRAINT [physical_lb_tracking_cc1] CHECK (([lb_tracking]='N' OR [lb_tracking]='Y'))
GO
ALTER TABLE [dbo].[physical] ADD CONSTRAINT [physical_serial_flag_cc1] CHECK (([serial_flag]=(1) OR [serial_flag]=(0)))
GO
CREATE NONCLUSTERED INDEX [phy_m1] ON [dbo].[physical] ([part_no], [location], [date_entered]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [phy1] ON [dbo].[physical] ([phy_batch], [phy_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [phyloc] ON [dbo].[physical] ([phy_batch], [phy_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[physical] TO [public]
GO
GRANT SELECT ON  [dbo].[physical] TO [public]
GO
GRANT INSERT ON  [dbo].[physical] TO [public]
GO
GRANT DELETE ON  [dbo].[physical] TO [public]
GO
GRANT UPDATE ON  [dbo].[physical] TO [public]
GO
