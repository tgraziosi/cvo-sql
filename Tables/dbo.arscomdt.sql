CREATE TABLE [dbo].[arscomdt]
(
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_id] [smallint] NOT NULL,
[bracket_id] [smallint] NOT NULL,
[from_bracket] [float] NOT NULL,
[to_bracket] [float] NOT NULL,
[bracket_amt] [float] NOT NULL,
[percent_flag] [float] NOT NULL,
[commissionable_amt] [float] NOT NULL,
[commission_amt] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arscomdt_ind_0] ON [dbo].[arscomdt] ([salesperson_code], [serial_id], [bracket_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arscomdt] TO [public]
GO
GRANT SELECT ON  [dbo].[arscomdt] TO [public]
GO
GRANT INSERT ON  [dbo].[arscomdt] TO [public]
GO
GRANT DELETE ON  [dbo].[arscomdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[arscomdt] TO [public]
GO
