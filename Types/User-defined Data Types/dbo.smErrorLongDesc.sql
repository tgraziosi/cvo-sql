CREATE TYPE [dbo].[smErrorLongDesc] FROM varchar (255) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smErrorLongDesc] TO [public]
GO
