CREATE TABLE [dbo].[cvo_lead_process_log]
(
[lead_id] [smallint] NOT NULL IDENTITY(1, 1),
[run_id] [smallint] NULL,
[fname] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lname] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_lead___count__66BCF68D] DEFAULT ('US'),
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[validAddress] [tinyint] NULL CONSTRAINT [DF__cvo_lead___valid__67B11AC6] DEFAULT ((0)),
[map_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[map_note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_lead_process_log] ADD CONSTRAINT [PK__cvo_lead_process__64D4AE1B] PRIMARY KEY CLUSTERED  ([lead_id]) ON [PRIMARY]
GO
