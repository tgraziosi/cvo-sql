CREATE TABLE [dbo].[cvo_crm_leads_address]
(
[addr_id] [int] NOT NULL IDENTITY(1, 1),
[addr_key] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isVerified] [tinyint] NULL CONSTRAINT [DF__cvo_crm_l__isVer__332875B8] DEFAULT ((0)),
[addr_date] [datetime] NULL CONSTRAINT [DF__cvo_crm_l__addr___341C99F1] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_leads_address] ADD CONSTRAINT [PK__cvo_crm_leads_ad__3234517F] PRIMARY KEY CLUSTERED  ([addr_id]) ON [PRIMARY]
GO
