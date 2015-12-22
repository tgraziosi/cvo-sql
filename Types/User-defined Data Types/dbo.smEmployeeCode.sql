CREATE TYPE [dbo].[smEmployeeCode] FROM char (9) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smEmployeeCode] TO [public]
GO
