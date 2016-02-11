CREATE TABLE [dbo].[cvo_tbb_requests]
(
[batch_id] [char] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rep_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[request_date] [datetime] NOT NULL,
[account_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_num] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_address] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[credit_act_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[credit_act_num] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_r__credi__333330E6] DEFAULT (NULL),
[credit_act_address] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_r__credi__3427551F] DEFAULT (NULL),
[request_type] [varchar] (70) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_r__reque__351B7958] DEFAULT (NULL),
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[color] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[size] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comments] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_tbb_r__comme__360F9D91] DEFAULT (NULL)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
