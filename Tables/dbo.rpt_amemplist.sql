CREATE TABLE [dbo].[rpt_amemplist]
(
[employee_code] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[employee_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[job_title] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amemplist] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amemplist] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amemplist] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amemplist] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amemplist] TO [public]
GO
