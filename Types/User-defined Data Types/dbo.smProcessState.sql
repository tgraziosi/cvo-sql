CREATE TYPE [dbo].[smProcessState] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smProcessState] TO [public]
GO
