CREATE TYPE [dbo].[smClientID] FROM char (20) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smClientID] TO [public]
GO
