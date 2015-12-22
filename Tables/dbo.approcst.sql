CREATE TABLE [dbo].[approcst]
(
[timestamp] [timestamp] NOT NULL,
[user_id] [smallint] NOT NULL,
[user_name] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date] [int] NOT NULL,
[post_flag] [int] NOT NULL,
[proc_num] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[proc_name] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_doc] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[approcst] TO [public]
GO
GRANT SELECT ON  [dbo].[approcst] TO [public]
GO
GRANT INSERT ON  [dbo].[approcst] TO [public]
GO
GRANT DELETE ON  [dbo].[approcst] TO [public]
GO
GRANT UPDATE ON  [dbo].[approcst] TO [public]
GO
