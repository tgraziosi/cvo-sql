CREATE TABLE [dbo].[EFORECAST_NOTES]
(
[PRODUCTID] [int] NOT NULL,
[STOREID] [int] NOT NULL,
[NOTE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EFORECAST_NOTES] ADD CONSTRAINT [PK_EFORECAST_NOTES] PRIMARY KEY CLUSTERED  ([PRODUCTID], [STOREID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EFORECAST_NOTES] ADD CONSTRAINT [FK_EFORECAST_NOTES_EFORECAST_PRODUCT_PRODUCTID] FOREIGN KEY ([PRODUCTID]) REFERENCES [dbo].[EFORECAST_PRODUCT] ([PRODUCTID])
GO
ALTER TABLE [dbo].[EFORECAST_NOTES] ADD CONSTRAINT [FK_EFORECAST_NOTES_EFORECAST_LOCATION_LOCATIONID] FOREIGN KEY ([STOREID]) REFERENCES [dbo].[EFORECAST_LOCATION] ([LOCATIONID])
GO
GRANT REFERENCES ON  [dbo].[EFORECAST_NOTES] TO [public]
GO
GRANT SELECT ON  [dbo].[EFORECAST_NOTES] TO [public]
GO
GRANT INSERT ON  [dbo].[EFORECAST_NOTES] TO [public]
GO
GRANT DELETE ON  [dbo].[EFORECAST_NOTES] TO [public]
GO
GRANT UPDATE ON  [dbo].[EFORECAST_NOTES] TO [public]
GO
