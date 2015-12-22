CREATE TABLE [dbo].[apfrmdet]
(
[timestamp] [timestamp] NOT NULL,
[form_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apfrmdet_ind_0] ON [dbo].[apfrmdet] ([form_code], [field_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apfrmdet] TO [public]
GO
GRANT SELECT ON  [dbo].[apfrmdet] TO [public]
GO
GRANT INSERT ON  [dbo].[apfrmdet] TO [public]
GO
GRANT DELETE ON  [dbo].[apfrmdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[apfrmdet] TO [public]
GO
