CREATE TABLE [dbo].[gledtlst]
(
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[error_code] [int] NOT NULL,
[char_param] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[spid] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [gledtlst_ind_0] ON [dbo].[gledtlst] ([spid], [journal_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gledtlst] TO [public]
GO
GRANT SELECT ON  [dbo].[gledtlst] TO [public]
GO
GRANT INSERT ON  [dbo].[gledtlst] TO [public]
GO
GRANT DELETE ON  [dbo].[gledtlst] TO [public]
GO
GRANT UPDATE ON  [dbo].[gledtlst] TO [public]
GO
