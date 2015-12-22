CREATE TABLE [dbo].[tdc_ip_screen]
(
[IP] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Screen_Size] [varchar] (7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_ip_screen] ADD CONSTRAINT [PK_tdc_ip_screen] PRIMARY KEY NONCLUSTERED  ([IP]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_ip_screen] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_ip_screen] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_ip_screen] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_ip_screen] TO [public]
GO
