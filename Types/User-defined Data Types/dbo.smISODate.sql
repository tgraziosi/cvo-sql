CREATE TYPE [dbo].[smISODate] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smISODate] TO [public]
GO
