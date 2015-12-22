CREATE TYPE [dbo].[smSegmentCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smSegmentCode] TO [public]
GO
