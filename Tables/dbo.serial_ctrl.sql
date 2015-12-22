CREATE TABLE [dbo].[serial_ctrl]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[issue_hold_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__serial_ct__issue__52D8916F] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[serial_ctrl] ADD CONSTRAINT [serial_ctrl_issue_hold_flag_cc1] CHECK (([issue_hold_flag]='A' OR [issue_hold_flag]='Q' OR [issue_hold_flag]='S' OR [issue_hold_flag]='C' OR [issue_hold_flag]='N' OR [issue_hold_flag]='Y'))
GO
CREATE UNIQUE CLUSTERED INDEX [serial_ctrl_pk] ON [dbo].[serial_ctrl] ([part_no], [serial_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[serial_ctrl] ADD CONSTRAINT [serial_ctrl_inv_master_fk1] FOREIGN KEY ([part_no]) REFERENCES [dbo].[inv_master] ([part_no])
GO
GRANT REFERENCES ON  [dbo].[serial_ctrl] TO [public]
GO
GRANT SELECT ON  [dbo].[serial_ctrl] TO [public]
GO
GRANT INSERT ON  [dbo].[serial_ctrl] TO [public]
GO
GRANT DELETE ON  [dbo].[serial_ctrl] TO [public]
GO
GRANT UPDATE ON  [dbo].[serial_ctrl] TO [public]
GO
