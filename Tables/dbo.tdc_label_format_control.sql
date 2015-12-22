CREATE TABLE [dbo].[tdc_label_format_control]
(
[module] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[format_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[input_prompt_count] [int] NOT NULL,
[input_prompt_select_0] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_3] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_4] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_5] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_6] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_7] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_8] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_select_9] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_0] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_1] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_2] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_3] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_4] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_5] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_6] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_7] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_8] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[input_prompt_result_9] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_label_format_control] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_label_format_control] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_label_format_control] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_label_format_control] TO [public]
GO
