CREATE TYPE [dbo].[smStringText] FROM varchar (255) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smStringText] TO [public]
GO
