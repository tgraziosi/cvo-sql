CREATE TABLE [dbo].[adm_arcontacts]
(
[timestamp] [timestamp] NOT NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_no] [smallint] NOT NULL,
[contact_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_fax] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_email] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [admarcon1] ON [dbo].[adm_arcontacts] ([customer_code], [ship_to_code], [contact_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_arcontacts] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_arcontacts] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_arcontacts] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_arcontacts] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_arcontacts] TO [public]
GO
