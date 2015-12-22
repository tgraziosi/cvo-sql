CREATE TABLE [dbo].[glsumdet]
(
[timestamp] [timestamp] NOT NULL,
[summary_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_pattern] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glsumdet_ind_0] ON [dbo].[glsumdet] ([summary_code], [account_pattern]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glsumdet] TO [public]
GO
GRANT SELECT ON  [dbo].[glsumdet] TO [public]
GO
GRANT INSERT ON  [dbo].[glsumdet] TO [public]
GO
GRANT DELETE ON  [dbo].[glsumdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[glsumdet] TO [public]
GO
