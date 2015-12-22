CREATE TABLE [dbo].[tdc_sec]
(
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_flag] [int] NULL,
[secgroup] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dist_method] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_sec__dist_me__47B0F786] DEFAULT ('01'),
[log_user] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_sec__log_use__48A51BBF] DEFAULT ('N'),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[language] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__tdc_sec__languag__49993FF8] DEFAULT ('us_english'),
[mdy_format] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_sec__mdy_for__4A8D6431] DEFAULT ('mm/dd/yy'),
[groupid] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userpw] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AppUser] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_sec] ADD CONSTRAINT [PK_tdc_sec_userid] PRIMARY KEY CLUSTERED  ([UserID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_sec] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_sec] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_sec] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_sec] TO [public]
GO
