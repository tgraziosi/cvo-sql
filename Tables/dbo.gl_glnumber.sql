CREATE TABLE [dbo].[gl_glnumber]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[next_src_ctrl_num] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glnumber_ind_0] ON [dbo].[gl_glnumber] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glnumber] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glnumber] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glnumber] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glnumber] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glnumber] TO [public]
GO
