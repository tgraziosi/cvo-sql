CREATE TYPE [dbo].[smAssetTypeCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smAssetTypeCode] TO [public]
GO
