CREATE TABLE [dbo].[cvo_tbb_orders]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rep_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[request_date] [datetime] NOT NULL,
[account_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_num] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_address] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[credit_act_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[credit_act_num] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__credi__4F6FAEAB] DEFAULT (NULL),
[credit_act_address] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__credi__5063D2E4] DEFAULT (NULL),
[request_type] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__reque__5157F71D] DEFAULT (NULL),
[request_items] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comments] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_o__comme__524C1B56] DEFAULT (NULL)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_tbb_orders] ADD CONSTRAINT [PK__cvo_tbb_orders__4E7B8A72] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
