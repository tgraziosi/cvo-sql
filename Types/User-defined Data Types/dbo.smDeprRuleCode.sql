CREATE TYPE [dbo].[smDeprRuleCode] FROM char (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smDeprRuleCode] TO [public]
GO
