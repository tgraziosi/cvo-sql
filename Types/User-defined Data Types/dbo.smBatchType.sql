CREATE TYPE [dbo].[smBatchType] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smBatchType] TO [public]
GO
