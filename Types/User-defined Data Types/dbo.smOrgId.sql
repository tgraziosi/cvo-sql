CREATE TYPE [dbo].[smOrgId] FROM varchar (30) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smOrgId] TO [public]
GO
