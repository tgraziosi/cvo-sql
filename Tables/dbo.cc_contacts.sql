CREATE TABLE [dbo].[cc_contacts]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_fax] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_email] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cc_contacts_idx] ON [dbo].[cc_contacts] ([customer_code], [contact_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_contacts] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_contacts] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_contacts] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_contacts] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_contacts] TO [public]
GO
