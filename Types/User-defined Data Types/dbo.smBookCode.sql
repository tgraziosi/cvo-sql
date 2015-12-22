CREATE TYPE [dbo].[smBookCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smBookCode] TO [public]
GO
