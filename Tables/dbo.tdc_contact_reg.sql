CREATE TABLE [dbo].[tdc_contact_reg]
(
[CompanyName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ContactPerson] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Title] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Address1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Address2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[City] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[State] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Country] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ZipCode] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Fax] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Email] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Platform] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SQLVersion] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ServerName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DatabaseName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DbInfo] [varchar] (600) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[InstallDate] [datetime] NULL,
[SerialNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AppType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_flag] [int] NULL,
[no_users] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_contact_reg] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_contact_reg] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_contact_reg] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_contact_reg] TO [public]
GO
