CREATE TABLE [dbo].[ntalrttv]
(
[var_name] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_1_prompt] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[op_1] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_2_prompt] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[help_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[help_text2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ntalrttv_ind_1] ON [dbo].[ntalrttv] ([var_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ntalrttv] TO [public]
GO
GRANT SELECT ON  [dbo].[ntalrttv] TO [public]
GO
GRANT INSERT ON  [dbo].[ntalrttv] TO [public]
GO
GRANT DELETE ON  [dbo].[ntalrttv] TO [public]
GO
GRANT UPDATE ON  [dbo].[ntalrttv] TO [public]
GO
