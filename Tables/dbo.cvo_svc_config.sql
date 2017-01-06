CREATE TABLE [dbo].[cvo_svc_config]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[territory] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rep_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isCustomEligible] [tinyint] NULL CONSTRAINT [DF__cvo_svc_c__isCus__6DDE2A11] DEFAULT ((0)),
[sv_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qop_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eor_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[suns_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[closeout_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[signature] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[aspire_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ch_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sunps_content] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_config] ADD CONSTRAINT [PK__cvo_svc_config__6CEA05D8] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
