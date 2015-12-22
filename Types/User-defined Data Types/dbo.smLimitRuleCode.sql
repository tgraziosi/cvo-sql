CREATE TYPE [dbo].[smLimitRuleCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLimitRuleCode] TO [public]
GO
