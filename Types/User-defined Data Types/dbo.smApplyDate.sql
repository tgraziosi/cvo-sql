CREATE TYPE [dbo].[smApplyDate] FROM datetime NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smApplyDate] TO [public]
GO
