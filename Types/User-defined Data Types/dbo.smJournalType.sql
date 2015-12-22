CREATE TYPE [dbo].[smJournalType] FROM varchar (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smJournalType] TO [public]
GO
