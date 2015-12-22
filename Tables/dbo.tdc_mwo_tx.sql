CREATE TABLE [dbo].[tdc_mwo_tx]
(
[mwo_number] [int] NOT NULL,
[mwo_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mwo_priority] [int] NOT NULL,
[mwo_status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reported_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reported_date_time] [datetime] NOT NULL,
[machine_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[request_description] [varchar] (3000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[accepted_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[accepted_date_time] [datetime] NULL,
[hold] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_mwo_tx__hold__011E7F0C] DEFAULT ('N'),
[hold_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_date_time] [datetime] NULL,
[hold_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[closed_cancelled] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_mwo_t__close__0212A345] DEFAULT ('N'),
[closed_cancelled_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[closed_cancelled_date_time] [datetime] NULL,
[repair_description] [varchar] (3000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[close_failure_class] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[close_problem_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[close_repair_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_mwo_tx] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_mwo_tx] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_mwo_tx] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_mwo_tx] TO [public]
GO
