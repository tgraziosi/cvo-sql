CREATE TYPE [dbo].[smBatchCode] FROM varchar (16) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smBatchCode] TO [public]
GO
