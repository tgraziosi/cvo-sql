CREATE TABLE [dbo].[appyt]
(
[timestamp] [timestamp] NOT NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[form_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[min_amt] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [appyt_ind_0] ON [dbo].[appyt] ([code_1099]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[appyt] TO [public]
GO
GRANT SELECT ON  [dbo].[appyt] TO [public]
GO
GRANT INSERT ON  [dbo].[appyt] TO [public]
GO
GRANT DELETE ON  [dbo].[appyt] TO [public]
GO
GRANT UPDATE ON  [dbo].[appyt] TO [public]
GO
