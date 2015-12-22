CREATE TYPE [dbo].[smUserName] FROM varchar (30) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smUserName] TO [public]
GO
