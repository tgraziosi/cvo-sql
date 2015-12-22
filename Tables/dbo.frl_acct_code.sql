CREATE TABLE [dbo].[frl_acct_code]
(
[acct_id] [numeric] (12, 0) NOT NULL IDENTITY(1, 1),
[entity_num] [smallint] NOT NULL,
[acct_code] [char] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_type] [smallint] NULL,
[acct_status] [tinyint] NOT NULL,
[acct_desc] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[normal_bal] [tinyint] NOT NULL,
[acct_group] [smallint] NOT NULL,
[nat_seg_code] [char] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rollup_level] [tinyint] NULL,
[activated_date] [datetime] NULL,
[last_used_date] [datetime] NULL,
[deactivated_date] [datetime] NULL,
[modify_flag] [tinyint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [XAK1frl_acct_code] ON [dbo].[frl_acct_code] ([acct_code], [entity_num], [rollup_level]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [XPKfrl_acct_code] ON [dbo].[frl_acct_code] ([acct_id], [entity_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE3frl_acct_code] ON [dbo].[frl_acct_code] ([entity_num], [acct_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE2frl_acct_code] ON [dbo].[frl_acct_code] ([entity_num], [modify_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE1frl_acct_code] ON [dbo].[frl_acct_code] ([nat_seg_code], [entity_num], [rollup_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_acct_code] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_acct_code] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_acct_code] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_acct_code] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_acct_code] TO [public]
GO
