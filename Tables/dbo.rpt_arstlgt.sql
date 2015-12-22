CREATE TABLE [dbo].[rpt_arstlgt]
(
[apinv] [float] NOT NULL,
[dis] [float] NOT NULL,
[wroff] [float] NOT NULL,
[gains] [float] NOT NULL,
[losses] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arstlgt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arstlgt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arstlgt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arstlgt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arstlgt] TO [public]
GO
