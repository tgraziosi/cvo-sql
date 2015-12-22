CREATE TYPE [dbo].[smGenericCode] FROM char (9) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smGenericCode] TO [public]
GO
