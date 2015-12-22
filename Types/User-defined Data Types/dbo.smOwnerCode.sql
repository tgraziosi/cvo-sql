CREATE TYPE [dbo].[smOwnerCode] FROM varchar (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smOwnerCode] TO [public]
GO
