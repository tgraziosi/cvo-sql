CREATE TABLE [dbo].[apmicr]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[sig_type] [smallint] NOT NULL,
[sig_image] [smallint] NOT NULL,
[sig_line1] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sig_line2] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sig_line3] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sig_line4] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sig_line5] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sig_line6] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[logo_type] [smallint] NOT NULL,
[logo_image] [smallint] NOT NULL,
[logo_line1] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[logo_line2] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[logo_line3] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[logo_line4] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[logo_line5] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[logo_line6] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[print_comp_address] [smallint] NOT NULL,
[on_us_symbol] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transit_symbol] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dash_symbol] [varchar] (21) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[split_date_format_flag] [smallint] NULL,
[date_format] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apmicr_ind_0] ON [dbo].[apmicr] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apmicr] TO [public]
GO
GRANT SELECT ON  [dbo].[apmicr] TO [public]
GO
GRANT INSERT ON  [dbo].[apmicr] TO [public]
GO
GRANT DELETE ON  [dbo].[apmicr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apmicr] TO [public]
GO
