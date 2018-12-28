CREATE TABLE [dbo].[cvo_sc_returnlabel_request_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[territory_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[request_date] [datetime] NULL CONSTRAINT [DF__cvo_sc_re__reque__2FA2C8EE] DEFAULT (getdate()),
[request_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_sc_re__isAct__3096ED27] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sc_returnlabel_request_log] ADD CONSTRAINT [PK__cvo_sc_returnlab__2EAEA4B5] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
