CREATE TYPE [dbo].[smAccountCode] FROM char (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smAccountCode] TO [public]
GO
