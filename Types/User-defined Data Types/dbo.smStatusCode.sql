CREATE TYPE [dbo].[smStatusCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smStatusCode] TO [public]
GO
