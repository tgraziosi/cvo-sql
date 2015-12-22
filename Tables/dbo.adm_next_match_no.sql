CREATE TABLE [dbo].[adm_next_match_no]
(
[timestamp] [timestamp] NOT NULL,
[last_no] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_next_match_no] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_next_match_no] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_next_match_no] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_next_match_no] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_next_match_no] TO [public]
GO
