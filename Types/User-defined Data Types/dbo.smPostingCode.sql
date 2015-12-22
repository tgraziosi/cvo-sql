CREATE TYPE [dbo].[smPostingCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smPostingCode] TO [public]
GO
