CREATE TABLE [dbo].[frl_entity]
(
[entity_num] [smallint] NOT NULL,
[entity_code] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entity_desc] [char] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_length] [tinyint] NULL,
[mask_length] [tinyint] NULL,
[acct_mask] [char] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_segs] [tinyint] NULL,
[natural_seg] [tinyint] NULL,
[rptng_curr_code] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[use_projects] [tinyint] NULL,
[use_multi_curr] [tinyint] NULL,
[use_debit_credit] [tinyint] NULL,
[use_trans_detl] [tinyint] NULL,
[use_net_amount] [tinyint] NULL,
[use_ytd_balance] [tinyint] NULL,
[use_acct_types] [tinyint] NULL,
[nat_start_char] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg_start_char] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acct_char] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[only_active_accts] [tinyint] NULL,
[index_built] [tinyint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [XPKfrl_entity] ON [dbo].[frl_entity] ([entity_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_entity] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_entity] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_entity] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_entity] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_entity] TO [public]
GO
