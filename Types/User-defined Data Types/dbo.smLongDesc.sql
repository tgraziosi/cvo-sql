CREATE TYPE [dbo].[smLongDesc] FROM varchar (255) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLongDesc] TO [public]
GO
