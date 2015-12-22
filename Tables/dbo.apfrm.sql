CREATE TABLE [dbo].[apfrm]
(
[timestamp] [timestamp] NOT NULL,
[form_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[form_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apfrm_ind_0] ON [dbo].[apfrm] ([form_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apfrm] TO [public]
GO
GRANT SELECT ON  [dbo].[apfrm] TO [public]
GO
GRANT INSERT ON  [dbo].[apfrm] TO [public]
GO
GRANT DELETE ON  [dbo].[apfrm] TO [public]
GO
GRANT UPDATE ON  [dbo].[apfrm] TO [public]
GO
