CREATE TYPE [dbo].[smControlNumber] FROM char (16) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smControlNumber] TO [public]
GO
