CREATE TYPE [dbo].[smGLSegmentCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smGLSegmentCode] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smGLSegmentCode]'
GO
