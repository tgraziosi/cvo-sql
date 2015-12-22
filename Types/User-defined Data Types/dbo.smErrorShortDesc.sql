CREATE TYPE [dbo].[smErrorShortDesc] FROM char (20) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smErrorShortDesc] TO [public]
GO
