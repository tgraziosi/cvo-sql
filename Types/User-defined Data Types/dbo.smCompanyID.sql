CREATE TYPE [dbo].[smCompanyID] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smCompanyID] TO [public]
GO
