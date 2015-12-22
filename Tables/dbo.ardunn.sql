CREATE TABLE [dbo].[ardunn]
(
[timestamp] [timestamp] NOT NULL,
[dunn_message_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dunn_message_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message3] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message4] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message5] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message6] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ardunn_ind_0] ON [dbo].[ardunn] ([dunn_message_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ardunn] TO [public]
GO
GRANT SELECT ON  [dbo].[ardunn] TO [public]
GO
GRANT INSERT ON  [dbo].[ardunn] TO [public]
GO
GRANT DELETE ON  [dbo].[ardunn] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardunn] TO [public]
GO
