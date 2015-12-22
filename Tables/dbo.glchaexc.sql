CREATE TABLE [dbo].[glchaexc]
(
[timestamp] [timestamp] NOT NULL,
[account_pattern] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glchaexc_ind_0] ON [dbo].[glchaexc] ([seg1_code], [seg2_code], [seg3_code], [seg4_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glchaexc] TO [public]
GO
GRANT SELECT ON  [dbo].[glchaexc] TO [public]
GO
GRANT INSERT ON  [dbo].[glchaexc] TO [public]
GO
GRANT DELETE ON  [dbo].[glchaexc] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchaexc] TO [public]
GO
