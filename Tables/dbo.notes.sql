CREATE TABLE [dbo].[notes]
(
[timestamp] [timestamp] NOT NULL,
[code_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[note_no] [int] NOT NULL,
[form] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pick] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pack] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bol] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[extra1] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[extra2] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[extra3] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[other] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [notes1] ON [dbo].[notes] ([code_type], [code], [line_no], [note_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [notes2] ON [dbo].[notes] ([code_type], [code], [note_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[notes] TO [public]
GO
GRANT SELECT ON  [dbo].[notes] TO [public]
GO
GRANT INSERT ON  [dbo].[notes] TO [public]
GO
GRANT DELETE ON  [dbo].[notes] TO [public]
GO
GRANT UPDATE ON  [dbo].[notes] TO [public]
GO
