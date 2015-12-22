CREATE TABLE [dbo].[gltaxbox]
(
[tax_box_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[gltaxbox] ADD CONSTRAINT [PK__gltaxbox__351A18A3] PRIMARY KEY CLUSTERED  ([tax_box_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltaxbox] TO [public]
GO
GRANT SELECT ON  [dbo].[gltaxbox] TO [public]
GO
GRANT INSERT ON  [dbo].[gltaxbox] TO [public]
GO
GRANT DELETE ON  [dbo].[gltaxbox] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltaxbox] TO [public]
GO
