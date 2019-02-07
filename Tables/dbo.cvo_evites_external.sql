CREATE TABLE [dbo].[cvo_evites_external]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[visit_date] [datetime] NULL,
[src_evite_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[web_cvo_account] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_evite_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isEviteActive] [tinyint] NULL CONSTRAINT [DF__cvo_evite__isEvi__72EEC069] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_evites_external] ADD CONSTRAINT [PK__cvo_evites_exter__5DF3A383] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
