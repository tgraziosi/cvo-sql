CREATE TYPE [dbo].[smLocationCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLocationCode] TO [public]
GO
