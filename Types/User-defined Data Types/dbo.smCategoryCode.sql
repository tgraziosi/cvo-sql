CREATE TYPE [dbo].[smCategoryCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smCategoryCode] TO [public]
GO
