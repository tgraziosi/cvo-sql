CREATE TABLE [dbo].[frl_acct_seg]
(
[seg_code] [char] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg_num] [tinyint] NOT NULL,
[entity_num] [smallint] NOT NULL,
[acct_id] [int] NOT NULL,
[acct_code] [char] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rollup_level] [tinyint] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [XIE1frl_acct_seg] ON [dbo].[frl_acct_seg] ([acct_id], [entity_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [XPKfrl_acct_seg] ON [dbo].[frl_acct_seg] ([seg_code], [seg_num], [acct_id], [entity_num], [rollup_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_acct_seg] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_acct_seg] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_acct_seg] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_acct_seg] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_acct_seg] TO [public]
GO
