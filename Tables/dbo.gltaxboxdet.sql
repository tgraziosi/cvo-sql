CREATE TABLE [dbo].[gltaxboxdet]
(
[tax_box_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_type_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltaxboxdet] TO [public]
GO
GRANT SELECT ON  [dbo].[gltaxboxdet] TO [public]
GO
GRANT INSERT ON  [dbo].[gltaxboxdet] TO [public]
GO
GRANT DELETE ON  [dbo].[gltaxboxdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltaxboxdet] TO [public]
GO
