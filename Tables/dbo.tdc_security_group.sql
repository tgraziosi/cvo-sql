CREATE TABLE [dbo].[tdc_security_group]
(
[GroupName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AppUser] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_security_group] ADD CONSTRAINT [PK_GroupName] PRIMARY KEY NONCLUSTERED  ([GroupName]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_security_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_security_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_security_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_security_group] TO [public]
GO
