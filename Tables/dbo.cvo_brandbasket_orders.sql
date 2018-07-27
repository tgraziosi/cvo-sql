CREATE TABLE [dbo].[cvo_brandbasket_orders]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rep_email] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[request_date] [datetime] NOT NULL,
[account_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_details] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pc_frames] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_brand__pc_fr__050283AC] DEFAULT (NULL),
[comments] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_brand__comme__05F6A7E5] DEFAULT (NULL)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_brandbasket_orders] ADD CONSTRAINT [PK__cvo_brandbasket___040E5F73] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
