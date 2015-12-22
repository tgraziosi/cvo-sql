CREATE TYPE [dbo].[smAccountCodeMask] FROM varchar (35) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smAccountCodeMask] TO [public]
GO
