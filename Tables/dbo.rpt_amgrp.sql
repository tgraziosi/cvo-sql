CREATE TABLE [dbo].[rpt_amgrp]
(
[group_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_id] [int] NOT NULL,
[group_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_edited] [tinyint] NOT NULL,
[group_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amgrp] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amgrp] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amgrp] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amgrp] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amgrp] TO [public]
GO
