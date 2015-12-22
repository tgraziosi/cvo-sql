CREATE TYPE [dbo].[smHostProcess] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smHostProcess] TO [public]
GO
