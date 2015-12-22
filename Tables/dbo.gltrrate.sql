CREATE TABLE [dbo].[gltrrate]
(
[timestamp] [timestamp] NOT NULL,
[override_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_comp_id] [smallint] NOT NULL,
[all_comp_flag] [smallint] NOT NULL,
[consol_type] [smallint] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[record_type] [smallint] NOT NULL,
[date] [int] NOT NULL,
[override_rate] [float] NOT NULL,
[rate_mode] [smallint] NULL,
[override_rate_oper] [float] NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [gltrrate_ind_0] ON [dbo].[gltrrate] ([override_code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gltrrate_ind_1] ON [dbo].[gltrrate] ([record_type], [consol_type], [sub_comp_id], [account_code], [date], [currency_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltrrate] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrrate] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrrate] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrrate] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrrate] TO [public]
GO
