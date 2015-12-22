CREATE TYPE [dbo].[smSmallCounter] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smSmallCounter] TO [public]
GO
