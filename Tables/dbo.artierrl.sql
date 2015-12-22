CREATE TABLE [dbo].[artierrl]
(
[timestamp] [timestamp] NOT NULL,
[relation_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[parent] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_1] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_2] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_3] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_4] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_5] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_6] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_7] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_8] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child_9] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rel_cust] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tier_level] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artierrl_ind_2] ON [dbo].[artierrl] ([rel_cust], [relation_code], [parent]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [artierrl_ind_0] ON [dbo].[artierrl] ([relation_code], [parent], [child_1], [child_2], [child_3], [child_4], [child_5], [child_6], [child_7], [child_8], [child_9]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [artierrl_ind_1] ON [dbo].[artierrl] ([relation_code], [tier_level], [rel_cust]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artierrl] TO [public]
GO
GRANT SELECT ON  [dbo].[artierrl] TO [public]
GO
GRANT INSERT ON  [dbo].[artierrl] TO [public]
GO
GRANT DELETE ON  [dbo].[artierrl] TO [public]
GO
GRANT UPDATE ON  [dbo].[artierrl] TO [public]
GO
