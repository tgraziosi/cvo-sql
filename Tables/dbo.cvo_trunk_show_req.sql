CREATE TABLE [dbo].[cvo_trunk_show_req]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[req_date] [datetime] NULL,
[show_date] [datetime] NULL,
[ship_to] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_start] [datetime] NULL,
[show_end] [datetime] NULL,
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_info] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_offer] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[counter_card] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[poster] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[large_window] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed_invitation] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invitation_amount] [float] NULL,
[bag_stuffer] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comments] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[digital_graphic] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_trunk__digit__3BAC7409] DEFAULT ('No'),
[prev_status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_trunk__email__3CA09842] DEFAULT ('No'),
[one_print_ad] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_trunk__one_p__3D94BC7B] DEFAULT ('No'),
[press_social_coverage] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_trunk__press__3E88E0B4] DEFAULT ('No'),
[status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_trunk__statu__3F7D04ED] DEFAULT ('Request Submitted'),
[kit_no] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[transfer] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sc_contacted] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rtn_tracking] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[received] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_memo] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rep_email] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_trunk__rep_e__1BE45256] DEFAULT (NULL)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_trunk_show_req] ADD CONSTRAINT [PK__cvo_trunk_show_r__3AB84FD0] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
