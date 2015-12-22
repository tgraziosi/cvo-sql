CREATE TABLE [dbo].[rpt_glconerr]
(
[seq_id] [int] NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_code] [int] NOT NULL,
[e_level] [int] NOT NULL,
[e_sdesc] [char] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[e_ldesc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[char_parm_1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char_parm_2] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glconerr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glconerr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glconerr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glconerr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glconerr] TO [public]
GO
